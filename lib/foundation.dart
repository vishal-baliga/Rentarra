if (!kIsWeb)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: _getCurrentLocation,
      icon: const Icon(Icons.my_location),
      label: const Text('Locate Me'),
    ),
  ),
