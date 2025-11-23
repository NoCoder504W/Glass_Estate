import 'package:hive/hive.dart';
import '../../domain/entities/apartment.dart';

part 'apartment_model.g.dart';

@HiveType(typeId: 0)
class ApartmentModel extends HiveObject {
  @HiveField(0)
  late String uid;

  @HiveField(1)
  late String bailleur;

  @HiveField(2)
  late String type;

  @HiveField(3)
  late String region;

  @HiveField(4)
  late String adresse;

  @HiveField(5)
  late String ville;

  @HiveField(6)
  late String cp;

  @HiveField(7)
  late double surface;

  @HiveField(8)
  late int etage;

  @HiveField(9)
  late double loyer;

  @HiveField(10)
  late bool hasAscenseur;

  @HiveField(11)
  late String descriptionParking;

  @HiveField(12)
  late String typeChauffage;

  @HiveField(13)
  late String plafondRef;

  @HiveField(14)
  double? latitude;

  @HiveField(15)
  double? longitude;

  @HiveField(16)
  bool isFavorite = false;

  static ApartmentModel fromDomain(Apartment apartment) {
    return ApartmentModel()
      ..uid = apartment.id
      ..bailleur = apartment.bailleur.name
      ..type = apartment.type
      ..region = apartment.region
      ..adresse = apartment.adresse
      ..ville = apartment.ville
      ..cp = apartment.cp
      ..surface = apartment.surface
      ..etage = apartment.etage
      ..loyer = apartment.loyer
      ..hasAscenseur = apartment.hasAscenseur
      ..descriptionParking = apartment.descriptionParking
      ..typeChauffage = apartment.typeChauffage
      ..plafondRef = apartment.plafondRef
      ..latitude = apartment.latitude
      ..longitude = apartment.longitude
      ..isFavorite = apartment.isFavorite;
  }

  Apartment toDomain() {
    return Apartment(
      id: uid,
      bailleur: Bailleur.values.firstWhere((e) => e.name == bailleur, orElse: () => Bailleur.social),
      type: type,
      region: region,
      adresse: adresse,
      ville: ville,
      cp: cp,
      surface: surface,
      etage: etage,
      loyer: loyer,
      hasAscenseur: hasAscenseur,
      descriptionParking: descriptionParking,
      typeChauffage: typeChauffage,
      plafondRef: plafondRef,
      latitude: latitude,
      longitude: longitude,
      isFavorite: isFavorite,
    );
  }
}
