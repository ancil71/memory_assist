import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_assist/features/guardian/services/face_service.dart';
import 'package:memory_assist/features/patient/services/face_recognition_service.dart';

class FaceScanScreen extends ConsumerStatefulWidget {
  final String patientId;
  const FaceScanScreen({super.key, required this.patientId});

  @override
  ConsumerState<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends ConsumerState<FaceScanScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  List<CameraDescription> _cameras = [];
  String? _scanMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Prefer back camera, fallback to first
        final camera = _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras.first);
        
        _controller = CameraController(camera, ResolutionPreset.medium);
        await _controller!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _scanFace() async {
    if (!_isCameraInitialized || _controller == null) return;

    setState(() {
      _isScanning = true;
      _scanMessage = 'Capturing Image...';
    });

    try {
      // 1. Take Picture
      final XFile image = await _controller!.takePicture();
      
      setState(() => _scanMessage = 'Analyzing Face...');
      
      setState(() => _scanMessage = 'Analyzing Face...');
      
      final recogService = ref.read(faceRecognitionServiceProvider);
      // Removed InputImage usage
      final faces = await recogService.detectFaces(image);
      
      if (faces.isEmpty) {
        throw Exception('No face detected. Try better lighting, look at the camera, or use a photo from gallery.');
      }

      setState(() => _scanMessage = 'Identifying Person...');

      // 3. Generate Embedding for captured face
      // Use alignedFace from FaceResult
      final capturedEmbedding = await recogService.generateEmbedding(faces.first.alignedFace);

      // 4. Fetch Guardian's Faces from Firestore
      final snapshot = await ref.read(faceServiceProvider).getFaces(widget.patientId).first;
      final storedFacesDocs = snapshot.docs;
      
      if (storedFacesDocs.isEmpty) {
         throw Exception('No faces found in database.');
      }

      final List<Map<String, dynamic>> storedFaces = storedFacesDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // 5. Compare
      final bestMatchName = recogService.findBestMatch(capturedEmbedding, storedFaces);

      if (!mounted) return;

      if (bestMatchName != null) {
        _showResultDialog(matchName: bestMatchName);
      } else {
        _showResultDialog(matchName: null); // Unknown
      }
      
      setState(() => _isScanning = false);

    } catch (e) {
      debugPrint('Scan Error: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _scanMessage = msg;
        });
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (xFile == null || !mounted) return;
    setState(() {
      _isScanning = true;
      _scanMessage = 'Analyzing photo...';
    });
    try {
      final recogService = ref.read(faceRecognitionServiceProvider);
      final faces = await recogService.detectFaces(xFile);
      if (faces.isEmpty) throw Exception('No face detected in this photo. Choose another.');
      setState(() => _scanMessage = 'Identifying...');
      final capturedEmbedding = await recogService.generateEmbedding(faces.first.alignedFace);
      final snapshot = await ref.read(faceServiceProvider).getFaces(widget.patientId).first;
      final storedFacesDocs = snapshot.docs;
      if (storedFacesDocs.isEmpty) throw Exception('No faces in database. Add faces from Guardian app first.');
      final storedFaces = storedFacesDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      final bestMatchName = recogService.findBestMatch(capturedEmbedding, storedFaces);
      if (!mounted) return;
      _showResultDialog(matchName: bestMatchName);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
    }
  }

  void _showResultDialog({String? matchName}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(matchName != null ? 'Person Identified' : 'Unknown Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              matchName != null ? Icons.check_circle : Icons.help_outline,
              size: 64,
              color: matchName != null ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              matchName ?? "This person is not in your familiar faces list.",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _scanMessage = null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(child: CameraPreview(_controller!)),

          // Overlay Scrim
          if (_isScanning)
            Container(color: Colors.black54),

          // Scanning Message
          if (_scanMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    _scanMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Capture Button
          if (!_isScanning)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: FloatingActionButton.large(
                  onPressed: _scanFace,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.camera, color: Colors.black, size: 40),
                ),
              ),
            ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Gallery fallback
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.photo_library, color: Colors.white),
                onPressed: _isScanning ? null : _scanFromGallery,
                tooltip: 'Use photo from device',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
