import 'package:isar/isar.dart';
import '../../domain/entities/apartment.dart';

part 'apartment_model.g.dart';

@collection
class ApartmentModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uid; // The UUID from domain

  late String bailleur; // Store enum as string
  late String type;
  late String region;
  late String adresse;
  late String ville;
  late String cp;
  late double surface;
  late int etage;
  late double loyer;
  late bool hasAscenseur;
  late String descriptionParking;
  late String typeChauffage;
  late String plafondRef;
  double? latitude;
  double? longitude;
  bool isFavorite = false;

  // Mapper: Domain -> Model
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

  // Mapper: Model -> Domain
  Apartment toDomain() {
    return Apartment(
      id: uid,
      bailleur: Bailleur.values.firstWhere((e) => e.name == bailleur, orElse: () => Bailleur.prive),
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
