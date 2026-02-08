import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final faceServiceProvider = Provider((ref) => FaceService());

class FaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFace({
    required String patientId,
    required File imageFile,
    required String name,
    required String relationship,
  }) async {
    try {
      // 1. Convert Image to Base64 String
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 2. Save Metadata + Image Data to Firestore
      // Note: Firestore has a 1MB limit per document. 
      // For a demo, this is fine. For production, resize/compress image before encoding.
      await _firestore.collection('faces').add({
        'patient_id': patientId,
        'name': name,
        'relationship': relationship,
        'image_base64': base64Image, // Changed from image_url
        'created_at': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('Error saving face: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getFaces(String patientId) {
    return _firestore
        .collection('faces')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> deleteFace(String docId) async {
    try {
      await _firestore.collection('faces').doc(docId).delete();
    } catch (e) {
      print('Error deleting face: $e');
    }
  }
}
