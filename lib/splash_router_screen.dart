import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'renter_onboarding_screen.dart'; // ✅ Correct file and class

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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized in SplashRouter');

      await Future.delayed(const Duration(seconds: 3));

      // Always go to onboarding (fresh flow)
      _goTo(const RenterOnboardingScreen());
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SpinKitCircle(color: Colors.teal, size: 100.0),
            SizedBox(height: 20),
            Text(
              "Loading Rentarra...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
