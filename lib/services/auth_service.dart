import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔑 Only people with this code become teachers. Keep it private.
  static const String teacherCode = 'NABTA-TEACHER-2026';

  // A stream the app watches to know if someone is logged in.
  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // SIGN UP — creates the auth account AND the users/ document with role.
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

    // Blank/wrong code = student. Correct code = teacher.
    final role =
        enteredTeacherCode.trim() == teacherCode ? 'teacher' : 'student';

    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // SIGN IN
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // SIGN OUT
  Future<void> signOut() async => _auth.signOut();

  // Reads the current user's role from Firestore.
  Future<String> roleOf(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'student';
  }
}