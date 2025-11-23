import 'package:freezed_annotation/freezed_annotation.dart';

part 'apartment.freezed.dart';
part 'apartment.g.dart';

enum Bailleur {
  social,
  prive,
}

@freezed
class Apartment with _$Apartment {
  const factory Apartment({
    required String id,
    required Bailleur bailleur,
    required String type,
    required String region,
    required String adresse,
    required String ville,
    required String cp,
    required double surface,
    required int etage,
    required double loyer,
    required bool hasAscenseur,
    required String descriptionParking,
    required String typeChauffage,
    required String plafondRef,
    double? latitude,
    double? longitude,
    @Default(false) bool isFavorite,
  }) = _Apartment;

  factory Apartment.fromJson(Map<String, dynamic> json) => _$ApartmentFromJson(json);
}
