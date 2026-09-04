import 'package:flutter/material.dart';

/// Grades offered in the app (primary school).
const List<String> kGrades = [
  'Grade 1',
  'Grade 2',
  'Grade 3',
  'Grade 4',
  'Grade 5',
  'Grade 6',
];

/// Color keys a teacher can pick for a subject tile.
const List<String> kSubjectColorKeys = [
  'blue',
  'green',
  'amber',
  'coral',
  'purple',
  'pink',
  'teal',
];

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
  if (n.contains('comput') || n.contains('حاسب') || n.contains('برمج')) return '💻';
  return '📚';
}

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
