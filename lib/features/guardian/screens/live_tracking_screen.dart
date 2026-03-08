import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String patientId;

  const LiveTrackingScreen({super.key, required this.patientId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  GeoPoint? _lastGeoPoint;

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking'), backgroundColor: Colors.teal),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.patientId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final geoPoint = data?['current_location'] as GeoPoint?;

          if (geoPoint == null) {
             return const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.location_off, size: 80, color: Colors.grey),
                   SizedBox(height: 16),
                   Text('Location not available yet.'),
                 ],
               ),
             );
          }

          // Animate camera if location changed
          if (_mapController != null && (_lastGeoPoint == null || 
              _lastGeoPoint!.latitude != geoPoint.latitude || 
              _lastGeoPoint!.longitude != geoPoint.longitude)) {
            _lastGeoPoint = geoPoint;
             _mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(geoPoint.latitude, geoPoint.longitude)),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(geoPoint.latitude, geoPoint.longitude),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // If we already have a point (which we do), ensure we look at it
                  // This is helpful if the initial render happens before the controller was ready
                  if (geoPoint != null) {
                     controller.moveCamera(CameraUpdate.newLatLng(LatLng(geoPoint.latitude, geoPoint.longitude)));
                  }
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('current_loc'),
                    position: LatLng(geoPoint.latitude, geoPoint.longitude),
                    infoWindow: const InfoWindow(title: 'Current Location'),
                  ),
                },
                myLocationEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _openMap(geoPoint.latitude, geoPoint.longitude),
                    icon: const Icon(Icons.map),
                    label: const Text('View in Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
