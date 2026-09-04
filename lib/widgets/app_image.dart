import 'package:flutter/material.dart';

/// 🖼️ IMAGE SLOT WIDGET
///
/// Put an illustration file into assets/images/ and show it with:
///     AppImage('hippo.png', width: 92)
///
/// TO RESIZE      -> change `width` (and/or `height`)
/// TO ADD A RING  -> ring: true  (white circle border + shadow, sticker look)
/// If the file is missing, a friendly emoji placeholder shows instead.
class AppImage extends StatelessWidget {
  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String placeholderEmoji;
  final bool ring;

  const AppImage(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholderEmoji = '🐣',
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/images/$name',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );

    if (!ring) return img;

    final d = (width ?? height ?? 80) + 8;
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: ClipOval(child: img),
    );
  }

  Widget _placeholder() {
    final size = width ?? height ?? 80;
    return Container(
      width: width,
      height: height ?? size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Text(placeholderEmoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}
