import 'package:flutter/material.dart';
import 'package:glass_estate/data/datasources/geocoding_service.dart';
import 'package:glass_estate/data/models/point_of_interest_model.dart';
import 'package:glass_estate/domain/entities/point_of_interest.dart';
import 'package:glass_estate/presentation/providers/apartment_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

final poiProvider = StateNotifierProvider<PoiNotifier, List<PointOfInterest>>((ref) {
  final isar = ref.watch(isarProvider);
  return PoiNotifier(isar, GeocodingService(isar));
});

class PoiNotifier extends StateNotifier<List<PointOfInterest>> {
  final Isar _isar;
  final GeocodingService _geocodingService;
  final _uuid = const Uuid();

  PoiNotifier(this._isar, this._geocodingService) : super([]) {
    loadPois();
  }

  Future<void> loadPois() async {
    final models = await _isar.pointOfInterestModels.where().findAll();
    state = models.map((e) => e.toDomain()).toList();
  }

  Future<void> addPoi(String name, String fullAddress, Color color) async {
    // Geocode
    // We pass the full address to the first parameter and empty strings for others
    // as the service concatenates them anyway.
    final coords = await _geocodingService.getCoordinates(fullAddress, '', '');
    
    double lat = 48.8566;
    double lng = 2.3522;

    if (coords != null) {
      lat = coords.latitude;
      lng = coords.longitude;
    } else {
      // If geocoding fails, we could throw an error or default.
      // For now, let's just log it and maybe the user will see it in Paris.
      print('Geocoding failed for POI: $fullAddress');
    }

    final poi = PointOfInterest(
      id: _uuid.v4(),
      name: name,
      address: fullAddress,
      latitude: lat,
      longitude: lng,
      colorValue: color.value,
      isVisible: true,
    );

    await _isar.writeTxn(() async {
      await _isar.pointOfInterestModels.put(PointOfInterestModel.fromDomain(poi));
    });

    await loadPois();
  }

  Future<void> toggleVisibility(String id) async {
    final poi = state.firstWhere((p) => p.id == id);
    final updated = poi.copyWith(isVisible: !poi.isVisible);
    
    await _isar.writeTxn(() async {
      final model = await _isar.pointOfInterestModels.filter().uidEqualTo(id).findFirst();
      if (model != null) {
        model.isVisible = updated.isVisible;
        await _isar.pointOfInterestModels.put(model);
      }
    });
    await loadPois();
  }

  Future<void> deletePoi(String id) async {
    await _isar.writeTxn(() async {
      await _isar.pointOfInterestModels.filter().uidEqualTo(id).deleteAll();
    });
    await loadPois();
  }

  Future<void> deleteAllPois() async {
    await _isar.writeTxn(() async {
      await _isar.pointOfInterestModels.where().deleteAll();
    });
    await loadPois();
  }
}
