import 'package:hive/hive.dart';

part 'geocoding_cache_model.g.dart';

@HiveType(typeId: 1)
class GeocodingCacheModel extends HiveObject {
  @HiveField(0)
  late String addressKey; // Normalized address string used for lookup

  @HiveField(1)
  late double latitude;

  @HiveField(2)
  late double longitude;
  
  @HiveField(3)
  late DateTime timestamp;
}
