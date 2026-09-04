import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Only people who enter this code at sign-up become teachers.
  /// Keep it private and share it only with real teachers.
  static const String teacherCode = 'NABTA-TEACHER-2026';

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String enteredTeacherCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final role =
        enteredTeacherCode.trim() == teacherCode ? 'teacher' : 'student';

    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async => _auth.signOut();

  Future<String> roleOf(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'student';
  }
}
