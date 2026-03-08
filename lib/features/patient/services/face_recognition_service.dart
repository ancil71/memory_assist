import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'face_recognition_service_stub.dart'
    if (dart.library.io) 'face_recognition_service_mobile.dart'
    if (dart.library.html) 'face_recognition_service_web.dart';

final faceRecognitionServiceProvider = Provider<FaceRecognitionService>((ref) {
  return getInstance();
});

abstract class FaceRecognitionService {
  Future<void> initialize();
  // Returns FaceResult objects. 
  Future<List<FaceResult>> detectFaces(XFile imageFile);
  
  // Takes the alignedFace from FaceResult (dynamic type to handle diff platforms)
  Future<List<double>> generateEmbedding(dynamic alignedFace);
  
  String? findBestMatch(List<double> capturedEmbedding, List<Map<String, dynamic>> storedFaces);
  void dispose();
}

class FaceResult {
  final Rect boundingBox;
  final dynamic alignedFace; // cv.Mat (Mobile) or JsObject (Web)

  FaceResult({required this.boundingBox, required this.alignedFace});
}
