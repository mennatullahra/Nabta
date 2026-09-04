class Subject {
  final String id;
  final String name;
  final String nameAr;
  final String iconColor;
  final int order;

  Subject({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconColor,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'iconColor': iconColor,
      'order': order,
    };
  }

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      iconColor: map['iconColor'] ?? 'green',
      order: map['order'] ?? 0,
    );
  }
}
