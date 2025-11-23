import 'package:flutter/material.dart';

class PointOfInterest {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int colorValue; // Store color as int
  final bool isVisible;

  PointOfInterest({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.colorValue,
    this.isVisible = true,
  });

  Color get color => Color(colorValue);
  
  PointOfInterest copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? colorValue,
    bool? isVisible,
  }) {
    return PointOfInterest(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      colorValue: colorValue ?? this.colorValue,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}
