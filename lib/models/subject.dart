class Subject {
  final String id;
  final String name;
  final String nameAr;
  final String iconColor;
  final int order;
  final String grade; // e.g. 'Grade 4'; empty = shown to all grades

  Subject({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconColor,
    required this.order,
    this.grade = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'iconColor': iconColor,
      'order': order,
      'grade': grade,
    };
  }

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      iconColor: map['iconColor'] ?? 'green',
      order: map['order'] ?? 0,
      grade: (map['grade'] ?? '').toString(),
    );
  }
}
