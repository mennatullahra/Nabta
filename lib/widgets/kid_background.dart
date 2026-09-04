import 'package:flutter/material.dart';

/// A cheerful sky background: soft gradient + a few coded clouds.
/// Wrap a screen body in this for the playful, illustrated feel.
/// (Clouds are drawn in code — no image needed. You can also drop
/// a full-screen background image instead using AppImage if you prefer.)
class KidBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  const KidBackground({
    super.key,
    required this.child,
    this.colors = const [Color(0xFFBFE6FF), Color(0xFFEAF7FF)],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 60, left: 20, child: _Cloud(scale: 1.0)),
          const Positioned(top: 120, right: 26, child: _Cloud(scale: 0.7)),
          const Positioned(top: 220, left: 40, child: _Cloud(scale: 0.5)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double scale;
  const _Cloud({required this.scale});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 96,
          height: 44,
          child: Stack(
            children: [
              Positioned(left: 0, top: 14, child: _c(30)),
              Positioned(left: 22, top: 0, child: _c(44)),
              Positioned(left: 52, top: 14, child: _c(32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _c(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
      );
}
