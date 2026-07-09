import 'package:flutter/material.dart';

class CompassArrow extends StatelessWidget {
  const CompassArrow({
    super.key,
    required this.turns,
    this.arrived = false,
    this.size = 156,
  });

  final double turns;
  final bool arrived;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primaryContainer,
          border: Border.all(color: colorScheme.primary.withValues(alpha: .2)),
        ),
        child: Center(
          child: AnimatedRotation(
            turns: turns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Icon(
              arrived ? Icons.check_circle : Icons.navigation,
              size: size * .56,
              color: arrived ? Colors.green.shade700 : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
