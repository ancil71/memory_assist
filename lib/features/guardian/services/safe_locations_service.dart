import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final safeLocationsServiceProvider = Provider((ref) => SafeLocationsService());

class SafeLocationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addLocation({
    required String patientId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _firestore.collection('safe_locations').add({
      'patient_id': patientId,
      'name': name,
      'address': address,
      'coordinates': GeoPoint(latitude, longitude),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getLocations(String patientId) {
    return _firestore
        .collection('safe_locations')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}
