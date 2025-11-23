import 'package:flutter/material.dart';
import 'package:glass_estate/data/datasources/geocoding_service.dart';
import 'package:glass_estate/data/models/point_of_interest_model.dart';
import 'package:glass_estate/domain/entities/point_of_interest.dart';
import 'package:glass_estate/presentation/providers/apartment_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final poiProvider = StateNotifierProvider<PoiNotifier, List<PointOfInterest>>((ref) {
  final poiBox = ref.watch(poiBoxProvider);
  final geocodingBox = ref.watch(geocodingBoxProvider);
  return PoiNotifier(poiBox, GeocodingService(geocodingBox));
});

class PoiNotifier extends StateNotifier<List<PointOfInterest>> {
  final Box<PointOfInterestModel> _box;
  final GeocodingService _geocodingService;
  final _uuid = const Uuid();

  PoiNotifier(this._box, this._geocodingService) : super([]) {
    loadPois();
  }

  Future<void> loadPois() async {
    state = _box.values.map((e) => e.toDomain()).toList();
  }

  Future<void> addPoi(String name, String fullAddress, Color color) async {
    // Geocode
    final coords = await _geocodingService.getCoordinates(fullAddress, '', '');
    
    double lat = 48.8566;
    double lng = 2.3522;

    if (coords != null) {
      lat = coords.latitude;
      lng = coords.longitude;
    } else {
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

    // Use UID as key
    await _box.put(poi.id, PointOfInterestModel.fromDomain(poi));

    await loadPois();
  }

  Future<void> toggleVisibility(String id) async {
    // Try to get by key (uid)
    PointOfInterestModel? model = _box.get(id);
    
    if (model == null) {
      try {
        model = _box.values.firstWhere((e) => e.uid == id);
      } catch (e) {
        // Not found
      }
    }

    if (model != null) {
      model.isVisible = !model.isVisible;
      await model.save();
    }
    await loadPois();
  }

  Future<void> deletePoi(String id) async {
    // Try to delete by key (uid)
    if (_box.containsKey(id)) {
      await _box.delete(id);
    } else {
      // Fallback: find key by uid
      final keyToDelete = _box.values.firstWhere((e) => e.uid == id).key;
      await _box.delete(keyToDelete);
    }
    await loadPois();
  }

  Future<void> deleteAllPois() async {
    await _box.clear();
    await loadPois();
  }
}
