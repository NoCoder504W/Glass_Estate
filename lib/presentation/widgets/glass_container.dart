import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart' as glass_kit;

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return glass_kit.GlassContainer(
      height: height ?? double.infinity,
      width: width ?? double.infinity,
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      blur: 15,
      borderWidth: 1.5,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      padding: padding ?? const EdgeInsets.all(16),
      // Dark Glass Style
      color: Colors.black.withOpacity(0.6),
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
      child: child,
    );
  }
}
