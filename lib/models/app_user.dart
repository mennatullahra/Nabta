class AppUser {
  final String uid;
  final String name;
  final String role; // 'teacher' or 'student'

  AppUser({required this.uid, required this.name, required this.role});

  bool get isTeacher => role == 'teacher';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
    );
  }
}