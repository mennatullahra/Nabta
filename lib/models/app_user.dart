class AppUser {
  final String uid;
  final String name;
  final String role; // 'teacher' or 'student'
  final String grade; // e.g. 'Grade 4' (students); empty for teachers

  AppUser({
    required this.uid,
    required this.name,
    required this.role,
    this.grade = '',
  });

  bool get isTeacher => role == 'teacher';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      grade: (map['grade'] ?? '').toString(),
    );
  }
}
