import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final faceServiceProvider = Provider((ref) => FaceService());

class FaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFace({
    required String patientId,
    required XFile imageFile,
    required String name,
    required String relationship,
    required List<double> embedding,
  }) async {
    try {
      // 1. Convert Image to Base64 String
      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 2. Save Metadata + Image Data to Firestore
      // Firestore 1MB limit check
      if (base64Image.length > 1000000) {
        throw Exception('Image too large. Please use a smaller image.');
      }

      await _firestore.collection('faces').add({
        'patient_id': patientId,
        'name': name,
        'relationship': relationship,
        'image_base64': base64Image,
        'embedding': embedding,
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
