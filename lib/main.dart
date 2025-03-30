// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart'; // 👈 Auto-generated from flutterfire configure

import 'login_screen.dart';
import 'signup_screen.dart';
import 'dashboards.dart';
import 'renter_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 Secure, platform-aware
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const LoginScreen();

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();

    // Safeguard: if user doc doesn't exist, treat as new
    if (!doc.exists) return const LoginScreen();

    final role = doc.data()?['role'] ?? 'renter';

    if (role == 'landlord') return const LandlordDashboard();

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;

    return onboardingComplete ? const RenterDashboard() : const RenterOnboardingScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentarra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const RenterDashboard(),
      },
    );
  }
}
