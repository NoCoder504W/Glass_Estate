import 'package:glass_estate/data/datasources/geocoding_service.dart';
import 'package:glass_estate/data/datasources/pdf_parsing_service.dart';
import 'package:glass_estate/data/models/apartment_model.dart';
import 'package:glass_estate/domain/entities/apartment.dart';
import 'package:glass_estate/domain/repositories/apartment_repository.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

class ApartmentRepositoryImpl implements ApartmentRepository {
  final PdfParsingService _parsingService;
  final GeocodingService _geocodingService;
  final Box<ApartmentModel> _box;

  ApartmentRepositoryImpl(this._parsingService, this._geocodingService, this._box);

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

    return LatLng(lat, lng);
  }

  @override
  Future<List<Apartment>> parseAndSavePdf(String pdfText, {void Function(int current, int total)? onProgress}) async {
    // 1. Parse new apartments
    final parsedApartments = _parsingService.parse(pdfText);
    final total = parsedApartments.length;

    // 2. Get existing apartments to handle sync
    // We assume keys are UIDs.
    final existingMap = <String, ApartmentModel>{};
    for (var model in _box.values) {
      existingMap[model.uid] = model;
    }

    // 3. Identify deletions (In DB but not in new list)
    final newIds = parsedApartments.map((a) => a.id).toSet();
    final idsToDelete = existingMap.keys.where((id) => !newIds.contains(id)).toList();

    if (idsToDelete.isNotEmpty) {
      // If we used UID as key, we can just delete by ID.
      // If not, we need to find the keys.
      // To be safe, we find keys from models.
      final keysToDelete = <dynamic>[];
      for (var id in idsToDelete) {
        final model = existingMap[id];
        if (model != null) {
          keysToDelete.add(model.key);
        }
      }
      await _box.deleteAll(keysToDelete);
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

      // Save to Hive (Update or Insert)
      // Use UID as key
      await _box.put(finalApt.id, ApartmentModel.fromDomain(finalApt));
    }

    return finalApartments;
  }

  @override
  Future<List<Apartment>> getSavedApartments() async {
    return _box.values.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<Apartment>> watchApartments() async* {
    // Emit initial value
    yield _box.values.map((e) => e.toDomain()).toList();
    
    // Watch for changes
    await for (final _ in _box.watch()) {
      yield _box.values.map((e) => e.toDomain()).toList();
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    // Try to get by key (uid)
    ApartmentModel? model = _box.get(id);
    
    // If not found by key, try to find by value (fallback if keys were not set correctly)
    if (model == null) {
      try {
        model = _box.values.firstWhere((e) => e.uid == id);
      } catch (e) {
        // Not found
      }
    }

    if (model != null) {
      model.isFavorite = !model.isFavorite;
      await model.save();
    }
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  @override
  Future<void> clearNonFavorites() async {
    final keysToDelete = <dynamic>[];
    for (var model in _box.values) {
      if (!model.isFavorite) {
        keysToDelete.add(model.key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }
}
