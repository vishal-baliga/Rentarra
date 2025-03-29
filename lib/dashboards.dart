import 'package:flutter/material.dart';
import 'post_property_screen.dart';
import 'view_properties_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'renter_onboarding_screen.dart';

class RenterDashboard extends StatefulWidget {
  const RenterDashboard({super.key});

  @override
  State<RenterDashboard> createState() => _RenterDashboardState();
}

class _RenterDashboardState extends State<RenterDashboard> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_complete') ?? false;

    if (!completed) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RenterOnboardingScreen()),
      );
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Renter Dashboard')),
      body: const Center(
        child: Text(
          'Welcome, Renter 👋',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}




/// 🔹 Landlord Dashboard with Post + View buttons
class LandlordDashboard extends StatelessWidget {
  const LandlordDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Landlord Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostPropertyScreen()),
                );
              },
              child: const Text("Post New Property"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewPropertiesScreen()),
                );
              },
              child: const Text("View Properties"),
            ),
          ],
        ),
      ),
    );
  }
}
