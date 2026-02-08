import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingScreen extends StatelessWidget {
  final String patientId;

  const LiveTrackingScreen({super.key, required this.patientId});

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking'), backgroundColor: Colors.teal),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading location'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final geoPoint = data?['current_location'] as GeoPoint?;
          final lastUpdated = data?['last_updated'] as Timestamp?;

          if (geoPoint == null) {
            return const Center(
              child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.location_off, size: 80, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('Location not available yet.', style: TextStyle(fontSize: 20)),
                 ],
              ),
            );
          }

          final String timeStr = lastUpdated != null 
              ? DateFormat('hh:mm:ss a').format(lastUpdated.toDate())
              : 'Unknown';

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 100, color: Colors.red),
                  const SizedBox(height: 32),
                  const Text('Current Location', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(
                    'Lat: ${geoPoint.latitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  Text(
                    'Lng: ${geoPoint.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last Updated: $timeStr',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(geoPoint.latitude, geoPoint.longitude),
                      icon: const Icon(Icons.map),
                      label: const Text('Open in Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
