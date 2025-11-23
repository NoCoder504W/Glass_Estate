import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// Model for a RER Line
class RerLine {
  final String name;
  final String ref;
  final Color color;
  final List<List<LatLng>> segments;

  RerLine({
    required this.name,
    required this.ref,
    required this.color,
    required this.segments,
  });
}

// State for the RER provider
class RerState {
  final bool isLoading;
  final List<RerLine> lines;
  final String? error;

  RerState({this.isLoading = false, this.lines = const [], this.error});
}

final rerProvider = StateNotifierProvider<RerNotifier, RerState>((ref) {
  return RerNotifier();
});

class RerNotifier extends StateNotifier<RerState> {
  RerNotifier() : super(RerState());

  bool _hasLoaded = false;

  Future<void> loadRerLines() async {
    if (_hasLoaded) return; // Load only once

    state = RerState(isLoading: true);

    try {
      // Bounding box for Île-de-France approx: South, West, North, East
      // 48.1, 1.7, 49.3, 3.3
      const bbox = '48.1,1.7,49.3,3.3';
      
      // Overpass API Query
      // We ask for relations with network=RER
      const query = '''
[out:json][timeout:25];
(
  relation["network"="RER"]($bbox);
);
out geom;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(url, body: {'data': query});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lines = _parseOverpassResponse(data);
        state = RerState(lines: lines, isLoading: false);
        _hasLoaded = true;
      } else {
        state = RerState(error: 'Failed to load RER data: ${response.statusCode}', isLoading: false);
      }
    } catch (e) {
      state = RerState(error: 'Error loading RER data: $e', isLoading: false);
    }
  }

  List<RerLine> _parseOverpassResponse(Map<String, dynamic> data) {
    final List<RerLine> rerLines = [];
    final elements = data['elements'] as List<dynamic>? ?? [];

    for (final element in elements) {
      if (element['type'] == 'relation') {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final members = element['members'] as List<dynamic>? ?? [];
        
        final ref = tags['ref'] as String? ?? 'Unknown';
        final name = tags['name'] as String? ?? 'RER $ref';
        final color = _getColorForRer(ref);

        final List<List<LatLng>> segments = [];

        for (final member in members) {
          if (member['type'] == 'way' && member['role'] == '') {
            // Some relations have geometry directly in members if "out geom" is used
            final geometry = member['geometry'] as List<dynamic>?;
            if (geometry != null) {
              final List<LatLng> points = [];
              for (final pt in geometry) {
                final lat = pt['lat'];
                final lon = pt['lon'];
                if (lat != null && lon != null) {
                  points.add(LatLng(lat, lon));
                }
              }
              if (points.isNotEmpty) {
                segments.add(points);
              }
            }
          }
        }

        if (segments.isNotEmpty) {
          rerLines.add(RerLine(
            name: name,
            ref: ref,
            color: color,
            segments: segments,
          ));
        }
      }
    }
    return rerLines;
  }

  Color _getColorForRer(String ref) {
    switch (ref.toUpperCase()) {
      case 'A': return const Color(0xFFE3051C); // RATP Red
      case 'B': return const Color(0xFF5291CE); // RATP Blue
      case 'C': return const Color(0xFFFFCE00); // SNCF Yellow
      case 'D': return const Color(0xFF00814F); // SNCF Green
      case 'E': return const Color(0xFFD580B2); // SNCF Magenta
      default: return Colors.grey;
    }
  }
}
