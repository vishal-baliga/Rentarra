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
  String? _userId;

  // Step 1: Check Firestore for email
  Future<void> _checkEmailExists() async {
    setState(() {
      _checkingEmail = true;
      _error = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (query.docs.isNotEmpty) {
        _userId = query.docs.first.id;
        setState(() {
          _emailExists = true;
        });
      } else {
        // Navigate to SignUpScreen with prefilled email
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpScreen(prefilledEmail: _emailController.text.trim()),
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

  // Step 2: Login with Firebase Auth
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      final role = snapshot.data()?['role']?.toLowerCase();

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
    return Scaffold(
      appBar: AppBar(title: const Text('Rentarra Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
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
                onPressed: _emailExists
                    ? (_loading ? null : _login)
                    : (_checkingEmail ? null : _checkEmailExists),
                child: Text(_emailExists ? 'Log In' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
