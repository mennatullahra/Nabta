class Course {
  final String id;
  final String subjectId;
  final String teacherId;
  final String teacherName;
  final String title;
  final String description;
  final String gradeLevel;
  final bool isPremium;
  final num price;
  final int lessonCount;

  Course({
    required this.id,
    required this.subjectId,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.gradeLevel,
    required this.isPremium,
    required this.price,
    required this.lessonCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'title': title,
      'description': description,
      'gradeLevel': gradeLevel,
      'isPremium': isPremium,
      'price': price,
      'lessonCount': lessonCount,
    };
  }

  factory Course.fromMap(String id, Map<String, dynamic> map) {
    return Course(
      id: id,
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      gradeLevel: map['gradeLevel'] ?? '',
      isPremium: map['isPremium'] ?? false,
      price: map['price'] ?? 0,
      lessonCount: map['lessonCount'] ?? 0,
    );
  }
}
