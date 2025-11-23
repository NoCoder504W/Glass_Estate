import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glass_estate/presentation/providers/poi_provider.dart';
import 'package:glass_estate/presentation/widgets/poi_glass_card.dart';
import 'package:glass_estate/presentation/widgets/poi_management_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:glass_estate/presentation/providers/apartment_provider.dart';
import 'package:glass_estate/presentation/widgets/apartment_glass_card.dart';
import 'package:glass_estate/presentation/widgets/filters_glass_dialog.dart';
import 'package:glass_estate/presentation/widgets/rer_lines_layer.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apartments = ref.watch(filteredApartmentsProvider);
    final pois = ref.watch(poiProvider);
    
    final selectedApartmentId = useState<String?>(null);
    final selectedPoiId = useState<String?>(null);
    final showRer = useState(true); // Toggle state for RER lines

    // Find the actual apartment object from the list to ensure we have the latest state (e.g. isFavorite)
    final selectedApartment = selectedApartmentId.value != null
        ? apartments.where((a) => a.id == selectedApartmentId.value).firstOrNull
        : null;

    final selectedPoi = selectedPoiId.value != null
        ? pois.where((p) => p.id == selectedPoiId.value).firstOrNull
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(48.8566, 2.3522), // Paris
              initialZoom: 12,
              onTap: (tapPosition, point) {
                selectedApartmentId.value = null;
                selectedPoiId.value = null;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              // RER Lines (Neon Effect)
              if (showRer.value)
                const RerLinesLayer(),
              
              MarkerLayer(
                markers: [
                  // Apartments
                  ...apartments.map((apt) {
                    if (apt.latitude == null || apt.longitude == null) return null;
                    return Marker(
                      point: LatLng(apt.latitude!, apt.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          selectedPoiId.value = null;
                          selectedApartmentId.value = apt.id;
                        },
                        child: Icon(
                          Icons.location_on,
                          color: apt.isFavorite ? Colors.redAccent : Colors.amberAccent,
                          size: 40,
                        ),
                      ),
                    );
                  }).whereType<Marker>(),

                  // POIs
                  ...pois.where((p) => p.isVisible).map((poi) {
                    return Marker(
                      point: LatLng(poi.latitude, poi.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          selectedApartmentId.value = null;
                          selectedPoiId.value = poi.id;
                        },
                        child: Icon(
                          Icons.star,
                          color: poi.color,
                          size: 40,
                          shadows: [
                            Shadow(color: poi.color.withOpacity(0.8), blurRadius: 10),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Selected Apartment Card (Bottom Sheet style)
          if (selectedApartment != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ApartmentGlassCard(
                apartment: selectedApartment,
                onTap: () {
                  // Navigate to details or toggle favorite
                  ref.read(apartmentProvider.notifier).toggleFavorite(selectedApartment.id);
                },
              ),
            ),

          // 3. Selected POI Card
          if (selectedPoi != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: PoiGlassCard(
                poi: selectedPoi,
                onDelete: () {
                  ref.read(poiProvider.notifier).deletePoi(selectedPoi.id);
                  selectedPoiId.value = null;
                },
              ),
            ),

          // 4. Import & Filter Buttons (Floating)
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    ref.read(apartmentProvider.notifier).pickAndExtractPdf();
                  },
                  label: const Text('Import PDF', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  elevation: 0,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const FiltersGlassDialog(),
                    );
                  },
                  label: const Text('Filtres', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  elevation: 0,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const PoiManagementDialog(),
                    );
                  },
                  label: const Text('Mes Points', style: TextStyle(color: Colors.white)),
                  icon: const Icon(Icons.star, color: Colors.white),
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  elevation: 0,
                ),
                const SizedBox(height: 10),
                // RER Toggle
                FloatingActionButton.small(
                  onPressed: () => showRer.value = !showRer.value,
                  backgroundColor: showRer.value ? Colors.amberAccent.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
                  elevation: 0,
                  child: const Text('RER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Nettoyage', style: TextStyle(color: Colors.white)),
                        content: const Text('Que voulez-vous supprimer ?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(apartmentProvider.notifier).clearNonFavorites();
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Non-favoris', style: TextStyle(color: Colors.amberAccent)),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(apartmentProvider.notifier).clearAll();
                              ref.read(poiProvider.notifier).deleteAllPois();
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('TOUT (Inclus Points)', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  elevation: 0,
                  child: const Icon(Icons.delete_forever, color: Colors.red),
                ),
              ],
            ),
          ),

          // 5. Non-blocking Progress Indicator (Bottom Left)
          _buildProgressCard(ref),
        ],
      ),
    );
  }

  Widget _buildProgressCard(WidgetRef ref) {
    final progress = ref.watch(importProgressProvider);
    final message = ref.watch(importStatusMessageProvider);

    // Only show if there is active progress or a message
    if (progress == null && message.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 20,
      right: 80, // Leave space for FABs if needed, or just left aligned
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (progress != null)
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      color: Colors.amberAccent,
                      backgroundColor: Colors.white10,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amberAccent),
              ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.isNotEmpty ? message : 'Traitement en cours...',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (progress != null)
                    const Text(
                      'Vous pouvez continuer à utiliser la carte',
                      style: TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed _buildLoadingOverlay as we use non-blocking UI now
}
