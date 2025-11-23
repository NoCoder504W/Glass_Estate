import 'package:isar/isar.dart';
import 'package:glass_estate/domain/entities/point_of_interest.dart';

part 'point_of_interest_model.g.dart';

@collection
class PointOfInterestModel {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true, replace: true)
  late String uid;
  
  late String name;
  late String address;
  late double latitude;
  late double longitude;
  late int colorValue;
  late bool isVisible;

  static PointOfInterestModel fromDomain(PointOfInterest poi) {
    return PointOfInterestModel()
      ..uid = poi.id
      ..name = poi.name
      ..address = poi.address
      ..latitude = poi.latitude
      ..longitude = poi.longitude
      ..colorValue = poi.colorValue
      ..isVisible = poi.isVisible;
  }

  PointOfInterest toDomain() {
    return PointOfInterest(
      id: uid,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      colorValue: colorValue,
      isVisible: isVisible,
    );
  }
}
