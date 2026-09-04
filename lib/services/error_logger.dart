import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Gives you visibility into crashes/errors WITHOUT the native
/// Crashlytics setup (which needs google-services files + Gradle plugins).
///
/// Every captured error is:
///   1. printed to the console (visible in `flutter run` / logcat), and
///   2. written best-effort to the `errorLogs` Firestore collection,
///      capped per app session so a bug can never run up your bill.
///
/// A teacher/admin can open `errorLogs` in the Firebase console to see
/// what went wrong on real devices. When you later outgrow this, swap in
/// firebase_crashlytics — the call sites stay the same.
class ErrorLogger {
  static int _sent = 0;
  static const int _maxPerSession = 20;

  static void init() {
    // Errors thrown inside the Flutter framework (build/layout/paint).
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      report(details.exception, details.stack,
          context: details.library ?? 'flutter');
    };
    // Uncaught errors from the platform/engine.
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, context: 'platform');
      return true;
    };
  }

  /// Call this from your own try/catch blocks for extra context.
  static void report(Object error, StackTrace? stack, {String context = ''}) {
    debugPrint('❌ [$context] $error');
    if (stack != null) debugPrint(stack.toString());

    if (_sent >= _maxPerSession) return;
    _sent++;

    // Fire-and-forget. Logging must NEVER throw or block the UI.
    () async {
      try {
        if (Firebase.apps.isEmpty) return;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return; // security rules require a signed-in user
        final msg = error.toString();
        final st = stack?.toString() ?? '';
        await FirebaseFirestore.instance.collection('errorLogs').add({
          'uid': uid,
          'context': context,
          'message': msg.length > 500 ? msg.substring(0, 500) : msg,
          'stack': st.length > 2000 ? st.substring(0, 2000) : st,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // swallow — never let logging cause a second failure
      }
    }();
  }
}
