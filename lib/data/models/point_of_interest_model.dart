import 'package:hive/hive.dart';
import 'package:glass_estate/domain/entities/point_of_interest.dart';

part 'point_of_interest_model.g.dart';

@HiveType(typeId: 2)
class PointOfInterestModel extends HiveObject {
  @HiveField(0)
  late String uid;
  
  @HiveField(1)
  late String name;

  @HiveField(2)
  late String address;

  @HiveField(3)
  late double latitude;

  @HiveField(4)
  late double longitude;

  @HiveField(5)
  late int colorValue;

  @HiveField(6)
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
