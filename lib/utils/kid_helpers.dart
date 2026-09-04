import 'package:flutter/material.dart';

/// Maps a stored color name to a bright, kid-friendly color.
Color subjectColor(String key) {
  switch (key) {
    case 'blue':
      return const Color(0xFF4A90E2);
    case 'green':
      return const Color(0xFF43B97F);
    case 'amber':
      return const Color(0xFFFFB03A);
    case 'coral':
      return const Color(0xFFFF6F61);
    case 'purple':
      return const Color(0xFF9B6DD6);
    case 'pink':
      return const Color(0xFFEC6EAD);
    case 'teal':
      return const Color(0xFF26C6DA);
    default:
      return const Color(0xFF43B97F);
  }
}

/// Picks a fun emoji for a subject based on its name (English or Arabic).
String subjectEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('math') || n.contains('رياض')) return '🔢';
  if (n.contains('scien') || n.contains('علوم')) return '🔬';
  if (n.contains('arab') || n.contains('عرب')) return '📖';
  if (n.contains('engl') || n.contains('نجليز') || n.contains('انجل')) return '🔤';
  if (n.contains('art') || n.contains('فن')) return '🎨';
  if (n.contains('relig') || n.contains('دين') || n.contains('اسلام')) return '🕌';
  if (n.contains('hist') || n.contains('تاريخ')) return '🏛️';
  if (n.contains('geo') || n.contains('جغراف')) return '🌍';
  if (n.contains('music') || n.contains('موسيق')) return '🎵';
  if (n.contains('sport') || n.contains('رياضة بدن') || n.contains('gym')) {
    return '⚽';
  }
  if (n.contains('comput') || n.contains('حاسب') || n.contains('برمج')) {
    return '💻';
  }
  return '📚';
}

/// A cheerful line of praise, rotated by a number (e.g. score).
String praise(int seed) {
  const lines = [
    'Awesome! 🎉',
    'Great job! 🌟',
    'You did it! 🚀',
    'Well done! 👏',
    'Super! ✨',
    'Brilliant! 🏆',
  ];
  return lines[seed % lines.length];
}
