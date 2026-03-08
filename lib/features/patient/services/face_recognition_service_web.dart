import 'dart:js_util' as js_util;
import 'dart:js' as js;
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'face_recognition_service.dart';

FaceRecognitionService getInstance() => FaceRecognitionServiceWeb();

class FaceRecognitionServiceWeb implements FaceRecognitionService {
  bool _isInitialized = false;

  FaceRecognitionServiceWeb() {
    _initialize();
  }
  
  @override
  Future<void> initialize() async => _initialize();

  Future<void> _initialize() async {
    // Call init on opencv_interop.js
    // assets/models/...
    // On web, assets are served at assets/assets/... or just assets/...
    // Flutter Web usually packs assets in 'assets' folder.
    // Full URL might be needed or relative path.
    // Try relative: 'assets/models/face_detection_yunet.onnx'
    
    try {
      final promise = js_util.callMethod(
        js_util.getProperty(html.window, 'opencvWeb'),
        'init',
        [
          'assets/assets/models/face_detection_yunet.onnx',
          'assets/assets/models/face_recognition_sface.onnx'
        ]
      );
      await js_util.promiseToFuture(promise);
      _isInitialized = true;
      print("OpenCV Web Models Loaded");
    } catch (e) {
      print("Error initializing Web OpenCV: $e");
    }
  }

  @override
  Future<List<FaceResult>> detectFaces(XFile imageFile) async {
    if (!_isInitialized) return [];

    // On web, XFile path is a blob URL
    final url = imageFile.path;
    
    final promise = js_util.callMethod(
      js_util.getProperty(html.window, 'opencvWeb'),
      'detect',
      [url]
    );
    
    final results = await js_util.promiseToFuture(promise);
    
    // results is a JS Array of objects {box, alignedFace, faceRow}
    List<FaceResult> faceResults = [];
    
    List<dynamic> list = List.from(results);
    for (var item in list) {
        var box = js_util.getProperty(item, 'box');
        var x = js_util.getProperty(box, 'x');
        var y = js_util.getProperty(box, 'y');
        var w = js_util.getProperty(box, 'w');
        var h = js_util.getProperty(box, 'h');
        
        var alignedFace = js_util.getProperty(item, 'alignedFace');
        
        faceResults.add(FaceResult(
            boundingBox: Rect.fromLTWH(x, y, w, h),
            alignedFace: alignedFace // Keep JS Object
        ));
    }
    
    return faceResults;
  }

  @override
  Future<List<double>> generateEmbedding(dynamic alignedFace) async {
    if (!_isInitialized) return [];

    final embeddingJs = js_util.callMethod(
      js_util.getProperty(html.window, 'opencvWeb'),
      'generateEmbedding',
      [alignedFace]
    );
    
    List<dynamic> list = List.from(embeddingJs);
    return list.cast<double>();
  }

  @override
  String? findBestMatch(List<double> capturedEmbedding, List<Map<String, dynamic>> storedFaces) {
      // Same logic as mobile
    if (capturedEmbedding.isEmpty) return null;

    double maxScore = 0.0;
    String? bestMatchName;
    const double threshold = 0.363; 

    for (var face in storedFaces) {
      if (face['embedding'] == null) continue;
      
      final List<dynamic> rawEmbedding = face['embedding'];
      final List<double> storedEmbedding = rawEmbedding.cast<double>();

      double score = _cosineSimilarity(capturedEmbedding, storedEmbedding);
      
      if (score > threshold && score > maxScore) {
        maxScore = score;
        bestMatchName = face['name'];
      }
    }
    return bestMatchName;
  }
  
  double _cosineSimilarity(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return -1.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < e1.length; i++) {
      dot += e1[i] * e2[i];
      normA += e1[i] * e1[i];
      normB += e2[i] * e2[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  @override
  void dispose() {}
}
