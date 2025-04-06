import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';

class RenterOnboardingScreen extends StatefulWidget {
  const RenterOnboardingScreen({super.key});

  @override
  State<RenterOnboardingScreen> createState() => _RenterOnboardingScreenState();
}

class _RenterOnboardingScreenState extends State<RenterOnboardingScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  final _places = GoogleMapsPlaces(apiKey: 'YOUR_API_KEY');

  final _cityController = TextEditingController();
  final _bedroomSelections = <String>{};
  final _commuteController = TextEditingController();
  String _commuteMode = 'Driving';
  double _budget = 1500;
  final _budgetTextController = TextEditingController(text: '1500');
  DateTime? _moveInDate;
  String _moveInImportance = '';
  List<String> _leaseLengths = [];
  List<String> _pets = [];
  List<String> _amenities = [];
  List<String> _preferences = [];
  double _income = 75000;
  final _incomeTextController = TextEditingController(text: '75000');
  List<String> _neighborhoodVibes = [];
  List<Prediction> _locationSuggestions = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _nextStep() {
    if (_currentStep == _steps.length - 1) {
      _saveAndContinue();
    } else {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep--);
  }

  void _saveAndContinue() {
    final onboardingData = {
      'city': _cityController.text.trim(),
      'bedrooms': _bedroomSelections.toList(),
      'commuteLocation': _commuteController.text.trim(),
      'commuteMode': _commuteMode,
      'budget': _budget.round(),
      'moveInDate': _moveInDate?.toIso8601String(),
      'moveInImportance': _moveInImportance,
      'leaseLengths': _leaseLengths,
      'pets': _pets,
      'amenities': _amenities,
      'preferences': _preferences,
      'income': _income.round(),
      'neighborhoodVibes': _neighborhoodVibes,
      'onboardingComplete': true,
    };

    Navigator.pushReplacementNamed(context, '/signup', arguments: onboardingData);
  }

  Future<void> _updateLocationSuggestions(String input) async {
    if (input.isEmpty) return;
    try {
      final response = await _places.autocomplete(input);
      if (response.isOkay) {
        setState(() => _locationSuggestions = response.predictions);
      } else {
        print('Autocomplete error: \${response.errorMessage}');
      }
    } catch (e) {
      print('Autocomplete exception: \$e');
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      setState(() {
        _cityController.text = '\${p.locality}, \${p.administrativeArea}';
      });
    }
  }

  List<Widget> get _steps => [
    _buildStep(
      icon: Icons.bed,
      title: 'Number of bedrooms & Lease length',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: ['1', '2', '3', '3+'].map((b) => ChoiceChip(
              label: Text(b),
              selected: _bedroomSelections.contains(b),
              onSelected: (_) => setState(() => _bedroomSelections.contains(b) ? _bedroomSelections.remove(b) : _bedroomSelections.add(b)),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: ['<6 months', '6 months', '12 months', 'Flexible'].map((o) => FilterChip(
              label: Text(o),
              selected: _leaseLengths.contains(o),
              onSelected: (selected) => setState(() => selected ? _leaseLengths.add(o) : _leaseLengths.remove(o)),
            )).toList(),
          )
        ],
      ),
    ),
    _buildStep(
      icon: Icons.date_range,
      title: 'Move-in Date & Importance',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now().add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _moveInDate = picked);
            },
            child: Text(_moveInDate == null ? 'Pick Date' : DateFormat.yMMMd().format(_moveInDate!)),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: ['Not important', 'Somewhat important', 'Very important'].map((o) => ChoiceChip(
              label: Text(o),
              selected: _moveInImportance == o,
              onSelected: (_) => setState(() => _moveInImportance = o),
            )).toList(),
          )
        ],
      ),
    ),
    _buildStep(
      icon: Icons.attach_money,
      title: 'Budget & Income',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Monthly Rent Budget'),
          Slider(
            value: _budget,
            min: 500,
            max: 2500,
            divisions: 20,
            label: '\$${_budget.round()}',
            onChanged: (val) => setState(() {
              _budget = val;
              _budgetTextController.text = val.round().toString();
            }),
          ),
          const SizedBox(height: 16),
          const Text('Monthly Household Income'),
          Slider(
            value: _income,
            min: 0,
            max: 200000,
            divisions: 40,
            label: '\$${_income.round()}',
            onChanged: (val) => setState(() {
              _income = val;
              _incomeTextController.text = val.round().toString();
            }),
          ),
        ],
      ),
    ),
    _buildStep(
      icon: Icons.location_city,
      title: 'City / Location',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City/Location'),
            onChanged: _updateLocationSuggestions,
          ),
          TextButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Locate Me'),
          ),
          ..._locationSuggestions.map((p) => ListTile(
                title: Text(p.description ?? ''),
                onTap: () => setState(() {
                  _cityController.text = p.description ?? '';
                  _locationSuggestions.clear();
                }),
              )),
        ],
      ),
    ),
    _buildStep(
      icon: Icons.directions_car,
      title: 'Regular Commute Location',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _commuteController,
            decoration: const InputDecoration(labelText: 'Commute Destination'),
            onChanged: _updateLocationSuggestions,
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: ['Driving', 'Transit', 'Walking', 'Bicycling'].map((mode) => ChoiceChip(
              label: Text(mode),
              selected: _commuteMode == mode,
              onSelected: (_) => setState(() => _commuteMode = mode),
            )).toList(),
          ),
        ],
      ),
    ),
    _buildStep(
      icon: Icons.chair,
      title: 'Preferred Amenities',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: ['Gym', 'Pool', 'Parking', 'Washer/Dryer', 'Furnished', 'Hard Wood Floors'].map((a) => FilterChip(
          label: Text(a),
          selected: _amenities.contains(a),
          onSelected: (selected) => setState(() => selected ? _amenities.add(a) : _amenities.remove(a)),
        )).toList(),
      ),
    ),
    _buildStep(
      icon: Icons.pets,
      title: 'Pets?',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: ['Dog', 'Cat', 'Bird', 'Other'].map((pet) => FilterChip(
          label: Text(pet),
          selected: _pets.contains(pet),
          onSelected: (selected) => setState(() => selected ? _pets.add(pet) : _pets.remove(pet)),
        )).toList(),
      ),
    ),
    _buildStep(
      icon: Icons.favorite,
      title: 'Desired Apartment Features',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: ['Commute', 'Natural Light', 'Quiet', 'Safety'].map((feature) => FilterChip(
          label: Text(feature),
          selected: _preferences.contains(feature),
          onSelected: (selected) => setState(() => selected ? _preferences.add(feature) : _preferences.remove(feature)),
        )).toList(),
      ),
    ),
    _buildStep(
      icon: Icons.explore,
      title: 'Preferred Neighborhood Vibe',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        children: ['🎉 Lively', '🎨 Artsy', '🧘 Quiet', '💼 Professional'].map((vibe) => FilterChip(
          label: Text(vibe),
          selected: _neighborhoodVibes.contains(vibe),
          onSelected: (selected) => setState(() => selected ? _neighborhoodVibes.add(vibe) : _neighborhoodVibes.remove(vibe)),
        )).toList(),
      ),
    ),
  ];

  Widget _buildStep({
    required IconData icon,
    required String title,
    required Widget child,
    bool showBack = false,
    bool isValid = true,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey<int>(_currentStep),
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(title, textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), speed: const Duration(milliseconds: 40)),
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
                if (showBack)
                  TextButton(
                    onPressed: _goBack,
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: isValid ? _nextStep : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
                    onPressed: () => Navigator.pushNamed(context, '/login'),
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