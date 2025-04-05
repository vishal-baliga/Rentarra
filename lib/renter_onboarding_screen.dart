import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class RenterOnboardingScreen extends StatefulWidget {
  const RenterOnboardingScreen({super.key});

  @override
  State<RenterOnboardingScreen> createState() => _RenterOnboardingScreenState();
}

class _RenterOnboardingScreenState extends State<RenterOnboardingScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  final _cityController = TextEditingController();
  final _places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');  // Replace with your API key
  List<Prediction> _locationSuggestions = [];

  final _bedroomController = TextEditingController();
  final _commuteController = TextEditingController();
  final _modeOfTransport = ['Driving', 'Transit', 'Walking', 'Bicycling'];
  String _selectedMode = 'Transit';
  final _budgetController = TextEditingController();
  DateTime? _moveInDate;
  String _dateImportance = 'Medium';
  final _leaseLengthOptions = ['6 months', '12 months', 'Flexible'];
  String _leaseLength = '12 months';
  String _petType = 'None';
  final _incomeController = TextEditingController();
  final _vibeOptions = ['Trendy', 'Artsy', 'Quiet', 'Lively'];
  final _selectedVibes = <String>[];
  final _preferenceOptions = ['Commute', 'Natural Light', 'Quiet', 'Safety'];
  final _selectedPreferences = <String>[];

  late List<Widget> _steps;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _steps = [
      _buildStep(
        icon: Icons.location_on,
        title: 'Which city/location are you looking in?',
        child: Column(
          children: [
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Start typing a city...'),
              onChanged: _updateLocationSuggestions,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Locate Me'),
              ),
            ),
            ..._locationSuggestions.map((p) => ListTile(
                  title: Text(p.description ?? ''),
                  onTap: () {
                    setState(() {
                      _cityController.text = p.description ?? '';
                      _locationSuggestions = [];
                    });
                  },
                )),
          ],
        ),
      ),
      _buildStep(
        icon: Icons.bed,
        title: 'How many bedrooms do you need?',
        child: TextField(
          controller: _bedroomController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Bedrooms'),
        ),
        showBack: true,
      ),
    ];
  }

  void _updateLocationSuggestions(String input) async {
    final response = await _places.autocomplete(input);
    if (response.isOkay) {
      setState(() => _locationSuggestions = response.predictions);
    }
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permission permanently denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      setState(() {
        _cityController.text = '${p.locality}, ${p.administrativeArea}';
      });
    }
  }

  int _safeInt(String value, {int fallback = 0}) {
    final n = int.tryParse(value.trim());
    return (n == null || n.isNaN) ? fallback : n;
  }

  Widget _buildStep({
    required IconData icon,
    required String title,
    required Widget child,
    bool showBack = false,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey<int>(_currentStep),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade100]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showBack)
              TextButton(onPressed: _goBack, child: const Text('Back')),
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(title,
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          speed: const Duration(milliseconds: 40)),
                    ],
                    isRepeatingAnimation: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _nextStep();
                  },
                  child: const Text('Skip →'),
                ),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _nextStep();
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep--);
  }

  void _nextStep() {
    if (_currentStep == _steps.length - 1) {
      _saveAndContinue();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Move this data save logic to the sign-up screen after user signs up
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/signup');  // Move to sign-up screen after onboarding.
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: _steps,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already signed up?'),
                  TextButton(
                    onPressed: () async {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Log in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
