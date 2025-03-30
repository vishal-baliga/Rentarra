import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RenterOnboardingScreen extends StatefulWidget {
  const RenterOnboardingScreen({super.key});

  @override
  State<RenterOnboardingScreen> createState() => _RenterOnboardingScreenState();
}

class _RenterOnboardingScreenState extends State<RenterOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _cityController = TextEditingController();
  final _places = GoogleMapsPlaces(apiKey: 'AIzaSyAi2FoBGhuNMEd1pXwNynU8dJm3jdTlXB4EY');
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

  List<Widget> _steps = [];

  @override
  void initState() {
    super.initState();
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
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      setState(() {
        _cityController.text = '${p.locality}, ${p.administrativeArea}';
      });
    }
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
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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

    await FirebaseFirestore.instance.collection('renterOnboarding').add({
      'userID': FirebaseAuth.instance.currentUser!.uid,
      'city': _cityController.text.trim(),
      'bedrooms': int.tryParse(_bedroomController.text.trim()) ?? 1,
      'commute': {
        'destination': _commuteController.text.trim(),
        'mode': _selectedMode
      },
      'budget': int.tryParse(_budgetController.text.trim()) ?? 0,
      'moveInDate': _moveInDate != null ? Timestamp.fromDate(_moveInDate!) : null,
      'dateImportance': _dateImportance,
      'leaseLength': _leaseLength,
      'pets': _petType,
      'preferences': _selectedPreferences,
      'householdIncome': int.tryParse(_incomeController.text.trim()) ?? 0,
      'vibe': _selectedVibes,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/dashboard');
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
                      final prefs = await SharedPreferences.getInstance();
                      final onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
                      Navigator.pushNamed(context, onboardingComplete ? '/dashboard' : '/login');
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
