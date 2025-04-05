import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    print('👋 User signed out.');
    setState(() {
      _emailExists = false;
      _emailController.clear();
      _passwordController.clear();
      _error = null;
    });
  }

  Future<void> _resetOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboardingComplete');
    print('🧹 Cleared onboardingComplete from SharedPreferences');

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await docRef.update({'onboardingComplete': false});
    print('🔥 Set onboardingComplete to false in Firestore');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Onboarding reset. Restart app to test.")),
    );
  }

  Future<void> _checkEmailExists() async {
    print('🛠️ Checking if email exists...');

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
        print('✅ Email found in Firestore');
        setState(() {
          _emailExists = true;
        });
      } else {
        print('🚨 Email not found. Redirecting to SignUp');
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
      print('❌ Error in _checkEmailExists: $e');
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
    print('🔐 Logging in...');

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('📧 Attempting login for: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        setState(() => _error = "User not found after login.");
        print('❌ User is null after sign in');
        return;
      }

      print('✅ Firebase user logged in: ${user.uid} (${user.email})');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => _error = "User record not found.");
        print('🚨 No user record in Firestore for ${user.email}');
        return;
      }

      final role = snapshot.docs.first.data()['role']?.toLowerCase();
      print('🔎 Role from Firestore: $role');

      if (role == 'renter') {
        final onboardingDoc = await FirebaseFirestore.instance
            .collection('renterOnboarding')
            .doc(user.uid)
            .get();

        final onboardingComplete = onboardingDoc.data()?['onboardingComplete'] == true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingComplete', onboardingComplete);

        if (onboardingComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RenterDashboard()),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      } else if (role == 'landlord') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LandlordDashboard()),
        );
      } else {
        setState(() => _error = "Unknown role assigned to this user.");
        print('❌ Unknown role: $role');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      setState(() {
        _error = "Login failed: ${e.message}";
      });
    } catch (e) {
      print('🔥 Unexpected error during login: $e');
      setState(() {
        _error = "Something went wrong. Please try again.";
      });
    } finally {
      setState(() {
        _loading = false;
        print('✅ Login flow completed. Loading stopped.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('📡 emailExists = $_emailExists');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Rentarra Login')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (FirebaseAuth.instance.currentUser != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _logout, child: const Text('Logout')),
                    TextButton(
                      onPressed: _resetOnboarding,
                      child: const Text('Reset Onboarding'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('onboardingComplete');
                        print('🚪 Dev Logout: signed out and cleared onboarding flag');
                        setState(() {
                          _emailController.clear();
                          _passwordController.clear();
                          _emailExists = false;
                          _error = null;
                        });
                      },
                      child: const Text('Dev Logout'),
                    ),
                  ],
                ),
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
                      : () {
                          print('🟢 Continue button pressed');
                          if (_emailExists) {
                            _login();
                          } else {
                            _checkEmailExists();
                          }
                        },
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
