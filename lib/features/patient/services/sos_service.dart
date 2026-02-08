import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sosServiceProvider = Provider((ref) => SOSService());

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> triggerSOS(String patientId) async {
    try {
      // 1. Get Location
      Position position = await _determinePosition();

      // 2. Create SOS Event
      await _firestore.collection('sos_events').add({
        'patient_id': patientId,
        'start_time': FieldValue.serverTimestamp(),
        'is_active': true,
        'location': GeoPoint(position.latitude, position.longitude),
        // 'audio_url': ... (Audio recording logic to be added)
      });
      
      print('SOS Triggered at ${position.latitude}, ${position.longitude}');

    } catch (e) {
      print('Error triggering SOS: $e');
      rethrow;
    }
  }

  // Helper to check permissions and get location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
