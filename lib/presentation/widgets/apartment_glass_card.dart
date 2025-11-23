import 'package:flutter/material.dart';
import 'package:glass_estate/domain/entities/apartment.dart';
import 'package:glass_estate/presentation/widgets/glass_container.dart';

class ApartmentGlassCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback? onTap;

  const ApartmentGlassCard({
    super.key,
    required this.apartment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        height: 150,
        width: double.infinity,
        child: Row(
          children: [
            // Left: Icon or Image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.apartment,
                size: 40,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 16),
            // Right: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${apartment.type} - ${apartment.surface} m²',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${apartment.ville} (${apartment.cp})',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${apartment.loyer.toStringAsFixed(0)} € / mois',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Favorite Icon
            Icon(
              apartment.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: apartment.isFavorite ? Colors.redAccent : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}
