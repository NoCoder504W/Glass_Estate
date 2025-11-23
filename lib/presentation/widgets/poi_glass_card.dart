import 'package:flutter/material.dart';
import 'package:glass_estate/domain/entities/point_of_interest.dart';
import 'package:glass_estate/presentation/widgets/glass_container.dart';

class PoiGlassCard extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback onDelete;

  const PoiGlassCard({
    super.key,
    required this.poi,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: 120,
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: poi.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: poi.color.withOpacity(0.5)),
            ),
            child: Icon(
              Icons.star,
              size: 30,
              color: poi.color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  poi.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  poi.address,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
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
                        Navigator.of(ctx).pop();
                        onDelete();
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
  }
}
