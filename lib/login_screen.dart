import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboards.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _emailExists = false;
  bool _checkingEmail = false;
  String? _error;

  Future<void> _checkEmailExists() async {
    setState(() {
      _checkingEmail = true;
      _error = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _emailExists = true;
        });
      } else {
        // New user → redirect to SignUp
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpScreen(
              prefilledEmail: _emailController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Something went wrong. Please try again.";
      });
    } finally {
      setState(() {
        _checkingEmail = false;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Sign in using email/password
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch role using currentUser's email
      final user = _auth.currentUser;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user?.email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _error = "User record not found.";
        });
        return;
      }

      final role = snapshot.docs.first.data()['role']?.toLowerCase();

      if (role == 'renter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RenterDashboard()),
        );
      } else if (role == 'landlord') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandlordDashboard()),
        );
      } else {
        setState(() {
          _error = "Unknown role assigned to this user.";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "Login failed.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Rentarra Login')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              if (_emailExists)
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              const SizedBox(height: 16),
              if (_checkingEmail || _loading)
                const Center(child: CircularProgressIndicator()),
              if (_error != null && !_checkingEmail && !_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_checkingEmail || _loading)
                      ? null
                      : (_emailExists ? _login : _checkEmailExists),
                  child: Text(_emailExists ? 'Log In' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
