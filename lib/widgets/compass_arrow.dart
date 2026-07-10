import 'package:flutter/material.dart';

import '../utils/constants.dart';

class CompassArrow extends StatefulWidget {
  const CompassArrow({
    super.key,
    required this.turns,
    this.arrived = false,
    this.size = 156,
  });

  /// Target rotation as a fraction of a full turn, normalized to `[0, 1)`.
  final double turns;
  final bool arrived;
  final double size;

  @override
  State<CompassArrow> createState() => _CompassArrowState();
}

class _CompassArrowState extends State<CompassArrow> {
  // Unbounded cumulative turns actually fed to AnimatedRotation. Because the
  // incoming [turns] wraps at the 0/1 boundary, animating it directly would
  // spin the arrow the long way around north. We instead move to the nearest
  // equivalent angle so the rotation always takes the shortest path.
  late double _displayTurns;

  @override
  void initState() {
    super.initState();
    _displayTurns = widget.turns;
  }

  @override
  void didUpdateWidget(covariant CompassArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turns != widget.turns) {
      _displayTurns = _nearestEquivalent(widget.turns, _displayTurns);
    }
  }

  // Returns the value congruent to [target] (mod 1) that is closest to
  // [reference], keeping successive rotations within a half turn.
  static double _nearestEquivalent(double target, double reference) {
    var delta = (target - reference) % 1.0;
    if (delta > 0.5) delta -= 1.0;
    return reference + delta;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.square(
      dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.secondary,
        ),
        child: Center(
          child: AnimatedRotation(
            turns: _displayTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Icon(
              widget.arrived ? Icons.check_circle : Icons.navigation,
              size: widget.size * .56,
              color: widget.arrived
                  ? const Color(AppColors.statusVerifiedText)
                  : colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
