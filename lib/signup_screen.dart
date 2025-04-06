import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboards.dart';

class SignUpScreen extends StatefulWidget {
  final String? prefilledEmail;
  const SignUpScreen({super.key, this.prefilledEmail});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  String _role = 'Renter';
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _onboardingData;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');

    // Capture onboarding data from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        setState(() {
          _onboardingData = args;
        });
      }
    });
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // Create user document
      await _firestore.collection('users').doc(uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingComplete': true,
      });

      // Save onboarding data if renter
      if (_role.toLowerCase() == 'renter' && _onboardingData != null) {
        _onboardingData!['userID'] = uid;
        _onboardingData!['submittedAt'] = FieldValue.serverTimestamp();
        _onboardingData!['onboardingComplete'] = true;

        await _firestore
            .collection('renterOnboarding')
            .doc(uid)
            .set(_onboardingData!, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up successful ✅")),
      );

      // Route based on role
      if (_role.toLowerCase() == 'renter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RenterDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandlordDashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "Something went wrong.";
      });
    } catch (e) {
      setState(() {
        _error = "Unexpected error: $e";
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
        appBar: AppBar(title: const Text('Rentarra Sign Up')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                autofocus: true,
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _role,
                onChanged: (value) => setState(() => _role = value!),
                items: const [
                  DropdownMenuItem(value: 'Renter', child: Text('Renter')),
                  DropdownMenuItem(value: 'Landlord', child: Text('Landlord')),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading) const CircularProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
