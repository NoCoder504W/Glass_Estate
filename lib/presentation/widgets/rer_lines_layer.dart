import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:glass_estate/presentation/providers/rer_provider.dart';

class RerLinesLayer extends HookConsumerWidget {
  const RerLinesLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rerState = ref.watch(rerProvider);

    // Trigger load if needed
    if (!rerState.isLoading && rerState.lines.isEmpty && rerState.error == null) {
      // Use Future.microtask to avoid build-time state updates
      Future.microtask(() => ref.read(rerProvider.notifier).loadRerLines());
    }

    if (rerState.isLoading && rerState.lines.isEmpty) {
      return const SizedBox.shrink(); // Or a small loader if desired
    }

    final polylines = <Polyline>[];

    for (final line in rerState.lines) {
      for (final segment in line.segments) {
        // 1. Outer Glow (Neon)
        polylines.add(Polyline(
          points: segment,
          strokeWidth: 6.0,
          color: line.color.withOpacity(0.4),
        ));
        
        // 2. Inner Core (Bright)
        polylines.add(Polyline(
          points: segment,
          strokeWidth: 2.0,
          color: line.color,
        ));
      }
    }

    return PolylineLayer(
      polylines: polylines,
    );
  }
}

