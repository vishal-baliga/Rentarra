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

  /// Determines the initial screen based on login, role, and onboarding status.
  Future<Widget> _getStartScreen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('🔐 No user logged in → LoginScreen');
        return const LoginScreen();
      }

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        print('📄 No user doc in Firestore → LoginScreen');
        return const LoginScreen();
      }

      final data = doc.data();
      final role = data?['role']?.toString().toLowerCase() ?? 'renter';
      final firestoreFlag = data?['onboardingComplete'] ?? false;

      print('🔎 Logged in as $role | Firestore onboardingComplete: $firestoreFlag');

      if (role == 'landlord') {
        return const LandlordDashboard();
      }

      // For renters → check onboarding status locally and remotely
      final prefs = await SharedPreferences.getInstance();
      final localFlag = prefs.getBool('onboardingComplete');
      final onboardingComplete = localFlag ?? firestoreFlag;

      print('🧠 Local onboardingComplete: $localFlag | Final: $onboardingComplete');

      return onboardingComplete
          ? const RenterDashboard()
          : const RenterOnboardingScreen();

    } catch (e) {
      print('🔥 Error in _getStartScreen(): $e');
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
