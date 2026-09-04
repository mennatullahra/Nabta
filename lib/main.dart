import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'models/app_user.dart';
import 'screens/auth_screen.dart';
import 'screens/subjects_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCWMHC3YGbossNVTu2S79c-mnwjK3cgiLA",
      authDomain: "courses-app-6476a.firebaseapp.com",
      projectId: "courses-app-6476a",
      storageBucket: "courses-app-6476a.firebasestorage.app",
      messagingSenderId: "1021100320655",
      appId: "1:1021100320655:web:fb2359b4b618bae9468dfa",
    ),
  );
  runApp(const NabtaApp());
}

class NabtaApp extends StatelessWidget {
  const NabtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nabta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

/// Decides which screen to show based on login state,
/// and loads the user's name + role once they're in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        if (!authSnap.hasData) {
          return const AuthScreen();
        }
        final uid = authSnap.data!.uid;
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final data = userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final appUser = AppUser.fromMap(uid, data);
            return SubjectsScreen(user: appUser);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌱', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Nabta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
