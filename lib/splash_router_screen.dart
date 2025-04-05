import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'renter_onboarding_screen.dart';
import 'dashboards.dart';

class SplashRouterScreen extends StatefulWidget {
  const SplashRouterScreen({super.key});

  @override
  State<SplashRouterScreen> createState() => _SplashRouterScreenState();
}

class _SplashRouterScreenState extends State<SplashRouterScreen> {
  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    try {
      // 🛡 Ensure Firebase is ready
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized in SplashRouter');

      // 🧪 Dev-only force logout & onboarding reset
      const isDev = bool.fromEnvironment('dart.vm.product') == false;
      if (isDev) {
        await FirebaseAuth.instance.signOut();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('onboardingComplete');
        print('🧹 Dev-only logout + onboarding flag cleared');
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _goTo(const LoginScreen());
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()?['role']?.toString().toLowerCase() ?? 'renter';
      final firestoreFlag = userDoc.data()?['onboardingComplete'] ?? false;

      final prefs = await SharedPreferences.getInstance();
      final localFlag = prefs.getBool('onboardingComplete');
      final onboardingComplete = localFlag ?? firestoreFlag;

      if (role == 'landlord') {
        _goTo(const LandlordDashboard());
      } else if (onboardingComplete) {
        _goTo(const RenterDashboard());
      } else {
        _goTo(const RenterOnboardingScreen());
      }
    } catch (e, stack) {
      print('🚨 Splash router error: $e');
      print(stack);
      _goTo(const LoginScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Loading Rentarra...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
