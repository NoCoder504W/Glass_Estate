import 'package:isar/isar.dart';

part 'geocoding_cache_model.g.dart';

@collection
class GeocodingCacheModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String addressKey; // Normalized address string used for lookup

  late double latitude;
  late double longitude;
  
  late DateTime timestamp;
}
