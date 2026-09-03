import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

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

  bool _isLogin = true;     // toggle between login and signup
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _busy = true; _error = null; });
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
      // On success, the auth gate (Step C) swaps the screen automatically.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Something went wrong');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 64, color: Colors.green),
              const SizedBox(height: 8),
              const Text('Nabta',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(_isLogin ? 'Welcome back' : 'Create your account',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              if (!_isLogin)
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full name', border: OutlineInputBorder()),
                ),
              if (!_isLogin) const SizedBox(height: 12),

              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
              ),

              if (!_isLogin) const SizedBox(height: 12),
              if (!_isLogin)
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Teacher code (optional)',
                    helperText: 'Leave blank to join as a student',
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 20),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isLogin ? 'Log in' : 'Sign up'),
                ),
              ),

              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() { _isLogin = !_isLogin; _error = null; }),
                child: Text(_isLogin
                    ? "New here? Create an account"
                    : "Already have an account? Log in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}