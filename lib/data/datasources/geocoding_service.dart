import 'dart:convert';
import 'package:glass_estate/data/models/geocoding_cache_model.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  final Isar _isar;
  
  // In-memory cache for current session speed
  final Map<String, LatLng?> _memoryCache = {};

  GeocodingService(this._isar);

  Future<LatLng?> getCoordinates(String address, String city, String zipCode) async {
    // Construct a query string
    final query = '$address, $city, $zipCode'.trim();
    
    // 1. Check Memory Cache
    if (_memoryCache.containsKey(query)) {
      return _memoryCache[query];
    }

    // 2. Check Persistent Cache (Isar)
    final cachedModel = await _isar.geocodingCacheModels.filter().addressKeyEqualTo(query).findFirst();
    if (cachedModel != null) {
      final coords = LatLng(cachedModel.latitude, cachedModel.longitude);
      _memoryCache[query] = coords;
      return coords;
    }

    // 3. Fetch from API
    int attempts = 0;
    while (attempts < 3) {
      try {
        final uri = Uri.parse(_baseUrl).replace(queryParameters: {
          'q': query,
          'format': 'json',
          'limit': '1',
          'addressdetails': '1',
        });

        final response = await http.get(uri, headers: {
          'User-Agent': 'GlassEstateApp/1.0 (contact@example.com)', 
        });

        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final coords = LatLng(lat, lon);
            
            // Save to caches
            _memoryCache[query] = coords;
            await _isar.writeTxn(() async {
              await _isar.geocodingCacheModels.put(GeocodingCacheModel()
                ..addressKey = query
                ..latitude = lat
                ..longitude = lon
                ..timestamp = DateTime.now()
              );
            });

            return coords;
          }
          // If empty, break to fallback
          break;
        } else if (response.statusCode == 429) {
          // Rate limit hit
          print('Nominatim Rate Limit (429) for $query. Waiting before retry...');
          await Future.delayed(Duration(seconds: 2 * (attempts + 1)));
          attempts++;
          continue;
        } else {
          print('Nominatim Error: ${response.statusCode}');
          break;
        }
      } catch (e) {
        print('Geocoding error for $query: $e');
        // Network error, maybe retry?
        await Future.delayed(const Duration(seconds: 1));
        attempts++;
      }
    }

    // Fallback: Try with just City and Zip if full address fails
    if (address.isNotEmpty) {
      return getCoordinates('', city, zipCode);
    }

    _memoryCache[query] = null;
    return null;
  }
}
