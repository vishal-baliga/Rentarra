import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'dashboards.dart';
import 'splash_router_screen.dart'; // ✅ Only import SplashRouter from here
import 'renter_onboarding_screen.dart'; // ✅ Only import the onboarding screen here

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentarra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SplashRouterScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const RenterDashboard(),
        '/onboarding': (context) => const RenterOnboardingScreen(), // ✅ Register route
      },
    );
  }
}
