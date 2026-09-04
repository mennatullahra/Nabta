import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  bool _isLogin = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        await _auth.signIn(email: _email.text, password: _password.text);
      } else {
        await _auth.signUp(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          enteredTeacherCode: _code.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e.code, e.message));
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(String code, String? fallback) {
    switch (code) {
      case 'weak-password':
        return 'Password is too short — use at least 6 characters.';
      case 'email-already-in-use':
        return 'That email already has an account. Try logging in.';
      case 'invalid-email':
        return 'That email doesn\'t look right.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password. Try again.';
      default:
        return fallback ?? 'Something went wrong.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFE6FF), Color(0xFFEAF7FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🖼️ WELCOME MASCOT — chick
                    const AppImage('nabta.png',
                        width: 120, ring: false, placeholderEmoji: '🐥'),
                    const SizedBox(height: 12),
                    const Text('Nabta',
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w800)),
                    Text(
                      _isLogin ? 'Welcome back! 👋' : 'Let\'s get started! 🚀',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              TextField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Your name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              TextField(
                                controller: _code,
                                decoration: const InputDecoration(
                                  labelText: 'Teacher code (optional)',
                                  helperText: 'Leave blank to join as a student',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.coral.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Color(0xFFC0392B)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : Text(_isLogin ? 'Log in' : 'Sign up'),
                              ),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _isLogin = !_isLogin;
                                        _error = null;
                                      }),
                              child: Text(_isLogin
                                  ? "New here? Create an account"
                                  : "Already have an account? Log in"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
