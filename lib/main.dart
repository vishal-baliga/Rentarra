// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'login_screen.dart';
import 'signup_screen.dart';
import 'dashboards.dart';
import 'renter_onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const LoginScreen();

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      // If no Firestore user doc exists, treat as new user
      if (!doc.exists) return const LoginScreen();

      final role = doc.data()?['role']?.toLowerCase() ?? 'renter';

      if (role == 'landlord') {
        return const LandlordDashboard();
      }

      // Check onboarding flag from SharedPreferences AND Firestore
      final prefs = await SharedPreferences.getInstance();
      final localFlag = prefs.getBool('onboardingComplete');
      final firestoreFlag = doc.data()?['onboardingComplete'] ?? false;
      final onboardingComplete = localFlag ?? firestoreFlag;

      return onboardingComplete
          ? const RenterDashboard()
          : const RenterOnboardingScreen();
    } catch (e) {
      // Fallback to login on error
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentarra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
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
