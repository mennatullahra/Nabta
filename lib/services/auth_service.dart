import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Everyone signs up as a STUDENT. This is enforced by security rules too,
  /// so the role can't be forged from the client. To create a teacher,
  /// an admin sets `role: "teacher"` on that user's document in the
  /// Firebase console (see PRODUCTION_CHECKLIST.md).
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String grade,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': 'student', // rules reject anything else at creation
      'grade': grade,
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
}
