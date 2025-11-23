import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:glass_estate/domain/entities/apartment.dart';
import 'package:glass_estate/presentation/providers/apartment_provider.dart';

class FiltersGlassDialog extends HookConsumerWidget {
  const FiltersGlassDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minSurface = ref.watch(filterMinSurfaceProvider);
    final maxLoyer = ref.watch(filterMaxLoyerProvider);
    final bailleur = ref.watch(filterBailleurProvider);
    final onlyFavorites = ref.watch(filterOnlyFavoritesProvider);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: GlassContainer(
          height: 500, // Increased height to avoid overflow
          width: 350,
          borderRadius: BorderRadius.circular(20),
          blur: 15,
          borderWidth: 1.5,
          borderColor: Colors.white.withOpacity(0.1),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtres',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Surface Min
                  const Text('Surface Minimum', style: TextStyle(color: Colors.white70)),
                  Slider(
                    value: (minSurface ?? 0).clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${minSurface?.round() ?? 0} m²',
                    activeColor: Colors.amberAccent,
                    onChanged: (val) {
                      ref.read(filterMinSurfaceProvider.notifier).state = val == 0 ? null : val;
                    },
                  ),
                  Text(
                    minSurface == null ? 'Peu importe' : '${minSurface.round()} m²',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 20),

                  // Loyer Max
                  const Text('Loyer Maximum', style: TextStyle(color: Colors.white70)),
                  Slider(
                    value: (maxLoyer ?? 2000).clamp(0, 2000),
                    min: 0,
                    max: 2000,
                    divisions: 40,
                    label: '${maxLoyer?.round() ?? 2000} €',
                    activeColor: Colors.amberAccent,
                    onChanged: (val) {
                      ref.read(filterMaxLoyerProvider.notifier).state = val == 2000 ? null : val;
                    },
                  ),
                  Text(
                    maxLoyer == null ? 'Peu importe' : '${maxLoyer.round()} €',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // Bailleur
                  const Text('Type de Bailleur', style: TextStyle(color: Colors.white70)),
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.black87, // For dropdown menu background
                    ),
                    child: DropdownButton<Bailleur?>(
                      value: bailleur,
                      dropdownColor: Colors.black87,
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.white54),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        ...Bailleur.values.map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.toString().split('.').last.toUpperCase()),
                        )),
                      ],
                      onChanged: (val) {
                        ref.read(filterBailleurProvider.notifier).state = val;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Favorites Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Favoris uniquement', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: onlyFavorites,
                        activeColor: Colors.amberAccent,
                        onChanged: (val) {
                          ref.read(filterOnlyFavoritesProvider.notifier).state = val;
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
