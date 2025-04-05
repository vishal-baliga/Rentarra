import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewPropertiesScreen extends StatelessWidget {
  const ViewPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertiesStream = FirebaseFirestore.instance
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Listed Properties")),
      body: StreamBuilder<QuerySnapshot>(
        stream: propertiesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong 😢\n${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No properties listed yet."));
          }

          final properties = snapshot.data!.docs;

          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final data = properties[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.home, size: 40),
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Text("${data['propertyType'] ?? 'Unknown'} • ${data['rent'] ?? '??'} USD/month"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Optional: Navigate to detailed screen
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
