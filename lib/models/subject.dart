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

  // Turns a Subject into a Map, so Firestore can store it.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'iconColor': iconColor,
      'order': order,
    };
  }

  // Rebuilds a Subject from a Firestore document.
  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      name: map['name'] ?? '',
      nameAr: map['nameAr'] ?? '',
      iconColor: map['iconColor'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}