import 'package:glass_estate/data/datasources/geocoding_service.dart';
import 'package:glass_estate/data/datasources/pdf_parsing_service.dart';
import 'package:glass_estate/data/models/apartment_model.dart';
import 'package:glass_estate/domain/entities/apartment.dart';
import 'package:glass_estate/domain/repositories/apartment_repository.dart';
import 'package:isar/isar.dart';

import 'package:latlong2/latlong.dart'; // Add this import

class ApartmentRepositoryImpl implements ApartmentRepository {
  final PdfParsingService _parsingService;
  final GeocodingService _geocodingService;
  final Isar _isar;

  ApartmentRepositoryImpl(this._parsingService, this._geocodingService, this._isar);

  LatLng _getFallbackCoordinates(Apartment apt) {
    double lat = 48.8566;
    double lng = 2.3522;
    
    if (apt.ville.toLowerCase().contains('lyon')) {
      lat = 45.7640;
      lng = 4.8357;
    } else if (apt.ville.toLowerCase().contains('marseille')) {
      lat = 43.2965;
      lng = 5.3698;
    } else if (apt.ville.toLowerCase().contains('clamart')) {
      lat = 48.8014;
      lng = 2.2628;
    }

    // REMOVED JITTER to avoid "line" effect
    // lat += (apt.id.hashCode % 1000 - 500) * 0.00005;
    // lng += (apt.id.hashCode % 1000 - 500) * 0.00005;

    return LatLng(lat, lng);
  }

  @override
  Future<List<Apartment>> parseAndSavePdf(String pdfText, {void Function(int current, int total)? onProgress}) async {
    // 1. Parse new apartments
    final parsedApartments = _parsingService.parse(pdfText);
    final total = parsedApartments.length;

    // 2. Get existing apartments to handle sync
    final existingModels = await _isar.apartmentModels.where().findAll();
    final existingMap = {for (var m in existingModels) m.uid: m};

    // 3. Identify deletions (In DB but not in new list)
    final newIds = parsedApartments.map((a) => a.id).toSet();
    final idsToDelete = existingMap.keys.where((id) => !newIds.contains(id)).toList();

    if (idsToDelete.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.apartmentModels.filter().anyOf(idsToDelete, (q, String id) => q.uidEqualTo(id)).deleteAll();
      });
      print('Deleted ${idsToDelete.length} obsolete apartments.');
    }

    // 4. Process new list (Update or Create)
    final finalApartments = <Apartment>[];
    
    for (int i = 0; i < parsedApartments.length; i++) {
      final apt = parsedApartments[i];
      
      // Notify progress
      if (onProgress != null) {
        onProgress(i + 1, total);
      }

      Apartment finalApt;
      final existingModel = existingMap[apt.id];
      bool needsGeocoding = true;

      if (existingModel != null) {
        // Check if existing coordinates are valid or if they look like fallback
        final fallback = _getFallbackCoordinates(apt);
        // Epsilon check for equality
        final isFallback = ((existingModel.latitude ?? 0) - fallback.latitude).abs() < 0.000001 && 
                           ((existingModel.longitude ?? 0) - fallback.longitude).abs() < 0.000001;
        
        if (!isFallback) {
          // Valid coordinates exist, keep them
          needsGeocoding = false;
          finalApt = apt.copyWith(
            latitude: existingModel.latitude,
            longitude: existingModel.longitude,
            isFavorite: existingModel.isFavorite,
          );
        } else {
          // Existing but fallback -> Retry geocoding
          needsGeocoding = true;
          // Preserve favorite status even if we re-geocode
          finalApt = apt.copyWith(isFavorite: existingModel.isFavorite);
        }
      } else {
        // New apartment
        needsGeocoding = true;
        finalApt = apt;
      }

      if (needsGeocoding) {
        // Rate limiting: 1.5 request per second max for Nominatim to be safe
        await Future.delayed(const Duration(milliseconds: 1500));
        
        final coords = await _geocodingService.getCoordinates(apt.adresse, apt.ville, apt.cp);
        
        if (coords != null) {
          finalApt = finalApt.copyWith(latitude: coords.latitude, longitude: coords.longitude);
        } else {
          // Fallback
          // If geocoding fails completely, we don't want to stack them or make a line.
          // We will just leave them with the fallback coordinates but without jitter if possible,
          // OR we can filter them out in the UI.
          // But the user complained about the "line".
          // Let's use the city center WITHOUT jitter for now, so they stack (less visible mess),
          // or better: check if we can try one last time with just the city.
          
          // Actually, the "line" comes from the jitter in _getFallbackCoordinates.
          // Let's REMOVE the jitter for now to satisfy the user request "points don't put themselves in the right place, they remake the line".
          // If we remove jitter, they will stack.
          
          double lat = 48.8566;
          double lng = 2.3522;
          
          if (apt.ville.toLowerCase().contains('lyon')) {
            lat = 45.7640;
            lng = 4.8357;
          } else if (apt.ville.toLowerCase().contains('marseille')) {
            lat = 43.2965;
            lng = 5.3698;
          } else if (apt.ville.toLowerCase().contains('clamart')) {
            lat = 48.8014;
            lng = 2.2628;
          }
          
          finalApt = finalApt.copyWith(latitude: lat, longitude: lng);
        }
      }
      
      finalApartments.add(finalApt);

      // Save to Isar (Update or Insert)
      await _isar.writeTxn(() async {
        await _isar.apartmentModels.put(ApartmentModel.fromDomain(finalApt));
      });
    }

    return finalApartments;
  }

  @override
  Future<List<Apartment>> getSavedApartments() async {
    final models = await _isar.apartmentModels.where().findAll();
    return models.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<Apartment>> watchApartments() {
    return _isar.apartmentModels.where().watch(fireImmediately: true).map((models) {
      return models.map((e) => e.toDomain()).toList();
    });
  }

  @override
  Future<void> toggleFavorite(String id) async {
    await _isar.writeTxn(() async {
      final model = await _isar.apartmentModels.filter().uidEqualTo(id).findFirst();
      if (model != null) {
        model.isFavorite = !model.isFavorite;
        await _isar.apartmentModels.put(model);
      }
    });
  }

  @override
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.apartmentModels.clear();
    });
  }

  @override
  Future<void> clearNonFavorites() async {
    await _isar.writeTxn(() async {
      await _isar.apartmentModels.filter().isFavoriteEqualTo(false).deleteAll();
    });
  }
}
