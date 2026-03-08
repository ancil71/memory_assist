import 'package:camera/camera.dart';
import 'face_recognition_service.dart';

FaceRecognitionService getInstance() => FaceRecognitionServiceMobile();

class FaceRecognitionServiceMobile implements FaceRecognitionService {
  @override
  Future<void> initialize() async {
    print("FaceRecognitionServiceMobile: Stubbed initialize");
  }

  @override
  Future<List<FaceResult>> detectFaces(XFile imageFile) async {
    return [];
  }

  @override
  Future<List<double>> generateEmbedding(dynamic alignedFace) async {
    return [];
  }

  @override
  String? findBestMatch(List<double> capturedEmbedding, List<Map<String, dynamic>> storedFaces) {
    return null;
  }

  @override
  void dispose() {}
}
