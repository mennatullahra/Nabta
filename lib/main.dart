import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme/app_theme.dart';
import 'models/app_user.dart';
import 'services/error_logger.dart';
import 'screens/auth_screen.dart';
import 'screens/subjects_screen.dart';

void main() {
  // runZonedGuarded catches async errors that escape the widget tree.
  runZonedGuarded(() async {
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
    ErrorLogger.init();
    runApp(const NabtaApp());
  }, (error, stack) {
    ErrorLogger.report(error, stack, context: 'zone');
  });
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

/// Decides which screen to show based on login state, and loads the
/// user's profile (name / role / grade) live so first-signup works
/// even before the Firestore doc has finished writing.
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
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.hasError) {
              return const _Message(
                emoji: '⚠️',
                text: 'Couldn\'t load your profile.\nCheck your connection.',
                showSignOut: true,
              );
            }
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            final doc = userSnap.data;
            if (doc == null || !doc.exists) {
              // Just after sign-up the doc may not exist yet; the stream
              // will update automatically once it's created.
              return const _Message(
                emoji: '🌱',
                text: 'Setting up your account...',
                showSignOut: true,
              );
            }
            final appUser = AppUser.fromMap(uid, doc.data() ?? {});
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

class _Message extends StatelessWidget {
  final String emoji;
  final String text;
  final bool showSignOut;
  const _Message(
      {required this.emoji, required this.text, this.showSignOut = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            if (showSignOut) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
