import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/safe_locations_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SafeLocationsScreen extends ConsumerWidget {
  final String patientId;

  const SafeLocationsScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MY PLACES', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFCC00), // High contrast Yellow
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ref.watch(safeLocationsServiceProvider).getLocations(patientId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading places'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final locations = snapshot.data!.docs;

          if (locations.isEmpty) {
            return const Center(child: Text('No safe places added yet.', style: TextStyle(fontSize: 24)));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: locations.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _LocationCard(
                  label: data['name'] ?? 'Unknown',
                  icon: Icons.place,
                  address: data['address'] ?? '',
                  color: Colors.lightBlueAccent,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String address;
  final Color color;

  const _LocationCard({
    required this.label,
    required this.icon,
    required this.address,
    required this.color,
  });

  Future<void> _openMap() async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 64, color: Colors.black87),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    label,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions, size: 48, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
