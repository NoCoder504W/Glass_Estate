import 'package:flutter/material.dart';
import 'package:glass_estate/presentation/providers/poi_provider.dart';
import 'package:glass_estate/presentation/widgets/add_poi_dialog.dart';
import 'package:glass_estate/presentation/widgets/glass_container.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PoiManagementDialog extends HookConsumerWidget {
  const PoiManagementDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poiProvider);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: GlassContainer(
          height: 500,
          width: 350,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes Points d\'Intérêt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                Expanded(
                  child: pois.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun point d\'intérêt',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: pois.length,
                          itemBuilder: (context, index) {
                            final poi = pois[index];
                            return ListTile(
                              leading: Icon(Icons.location_on, color: poi.color),
                              title: Text(
                                poi.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                poi.address,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: poi.isVisible,
                                    activeColor: poi.color,
                                    onChanged: (val) {
                                      ref.read(poiProvider.notifier).toggleVisibility(poi.id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white54),
                                    onPressed: () {
                                      // Confirm delete
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: Colors.grey[900],
                                          title: const Text('Supprimer ?', style: TextStyle(color: Colors.white)),
                                          content: Text('Voulez-vous supprimer "${poi.name}" ?', style: const TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Annuler'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                ref.read(poiProvider.notifier).deletePoi(poi.id);
                                                Navigator.of(ctx).pop();
                                              },
                                              child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddPoiDialog(
                        onSave: (name, address, color) {
                          ref.read(poiProvider.notifier).addPoi(name, address, color);
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un point'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
