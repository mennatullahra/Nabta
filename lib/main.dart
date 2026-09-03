import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/subjects_screen.dart';
import 'screens/auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/app_user.dart';

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nabta',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Not logged in → login screen.
        if (!authSnap.hasData) {
          return const AuthScreen();
        }
        // Logged in → fetch their users/ document to get name + role.
        final uid = authSnap.data!.uid;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
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