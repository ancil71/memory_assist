import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final faceServiceProvider = Provider((ref) => FaceService());

class FaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<void> addFace({
    required String patientId,
    required File imageFile,
    required String name,
    required String relationship,
  }) async {
    try {
      final String imageId = _uuid.v4();
      final String path = 'faces/$patientId/$imageId.jpg';
      
      // 1. Upload Image to Firebase Storage
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);
      final String downloadUrl = await uploadTask.ref.getDownloadURL();

      // 2. Save Metadata to Firestore
      await _firestore.collection('faces').add({
        'patient_id': patientId,
        'name': name,
        'relationship': relationship,
        'image_url': downloadUrl,
        'created_at': FieldValue.serverTimestamp(),
        // 'embedding': ... (Add this later when integrating TFLite)
      });
      
    } catch (e) {
      print('Error uploading face: $e');
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

  Future<void> deleteFace(String docId, String imageUrl) async {
    try {
      await _firestore.collection('faces').doc(docId).delete();
      await _storage.refFromURL(imageUrl).delete();
    } catch (e) {
      print('Error deleting face: $e');
      // Rethrow if you want to show error to user
    }
  }
}
