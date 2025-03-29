import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;


class PostPropertyScreen extends StatefulWidget {
  const PostPropertyScreen({super.key});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rentController = TextEditingController();
  final _locationController = TextEditingController();
  final _sqftController = TextEditingController();

  String _propertyType = 'Apartment';
  int _bedrooms = 1;
  int _bathrooms = 1;
  File? _selectedImage;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;


  bool _loading = false;
  String? _error;

  Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    if (kIsWeb) {
      _selectedImageBytes = await image.readAsBytes();
    } else {
      _selectedImagePath = image.path;
    }
    setState(() {}); // Refresh the UI
  }
}



  Future<void> _submitProperty() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = "User not logged in.";
          _loading = false;
        });
        return;
      }

    String? imageUrl;
    if (_selectedImage != null) {
    final storageRef = FirebaseStorage.instance
      .ref()
      .child('property_images')
      .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();
  }   

await FirebaseFirestore.instance.collection('properties').add({
  'title': _titleController.text.trim(),
  'description': _descriptionController.text.trim(),
  'rent': double.tryParse(_rentController.text.trim()) ?? 0,
  'location': _locationController.text.trim(),
  'propertyType': _propertyType,
  'bedrooms': _bedrooms,
  'bathrooms': _bathrooms,
  'squareFootage': int.tryParse(_sqftController.text.trim()) ?? 0,
  'imageUrl': imageUrl,
  'landlordId': user.uid,
  'createdAt': FieldValue.serverTimestamp(),
});


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property listed successfully ✅')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = "Something went wrong. Try again.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post Property")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Property Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _rentController,
              decoration: const InputDecoration(labelText: 'Rent (USD)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _propertyType,
              onChanged: (value) => setState(() => _propertyType = value!),
              decoration: const InputDecoration(labelText: 'Property Type'),
              items: const [
                DropdownMenuItem(value: 'Apartment', child: Text('Apartment')),
                DropdownMenuItem(value: 'House', child: Text('House')),
                DropdownMenuItem(value: 'Studio', child: Text('Studio')),
                DropdownMenuItem(value: 'Townhome', child: Text('Townhome')),
                DropdownMenuItem(value: 'Shared Room', child: Text('Shared Room')),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _bedrooms,
              onChanged: (value) => setState(() => _bedrooms = value!),
              decoration: const InputDecoration(labelText: 'Bedrooms'),
              items: List.generate(10, (i) => i + 1)
                  .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                  .toList(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _bathrooms,
              onChanged: (value) => setState(() => _bathrooms = value!),
              decoration: const InputDecoration(labelText: 'Bathrooms'),
              items: List.generate(10, (i) => i + 1)
                  .map((val) => DropdownMenuItem(value: val, child: Text('$val')))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sqftController,
              decoration: const InputDecoration(labelText: 'Square Footage'),
              keyboardType: TextInputType.number,
            ), 
            const SizedBox(height: 16),
            _outlinedImagePicker(context),

            const SizedBox(height: 20),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitProperty,
                child: const Text("Submit Property"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlinedImagePicker(BuildContext context) {
  return InkWell(
    onTap: _pickImage,
    child: Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _selectedImageBytes != null
          ? kIsWeb
              ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
              : Image.file(File(_selectedImagePath!), fit: BoxFit.cover)
          : const Center(child: Text("Tap to select image")),
    ),
  );
}

}
