import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchProperties() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('properties').get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Discover Properties")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final properties = snapshot.data ?? [];

          if (properties.isEmpty) {
            return const Center(child: Text("No properties found."));
          }

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(property['title'] ?? 'Untitled'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Rent: \$${property['rent'] ?? 'N/A'}"),
                        Text("Location: ${property['location'] ?? 'N/A'}"),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to property detail screen
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
