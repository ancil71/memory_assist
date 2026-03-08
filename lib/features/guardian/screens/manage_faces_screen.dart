import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/face_service.dart';
import 'package:memory_assist/features/patient/services/face_recognition_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageFacesScreen extends ConsumerStatefulWidget {
  final String? patientId; // Optional: If managed by Guardian for specific patient

  const ManageFacesScreen({super.key, this.patientId});

  @override
  ConsumerState<ManageFacesScreen> createState() => _ManageFacesScreenState();
}

class _ManageFacesScreenState extends ConsumerState<ManageFacesScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();

  Future<void> _showAddSourceChoice() async {
    if (_isUploading) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo with camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from device (gallery)'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _addFace(source);
  }

  Future<void> _addFace(ImageSource source) async {
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 600,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
      return;
    }

    if (pickedFile == null) return;
    if (!mounted) return;

    _nameController.clear();
    _relationController.clear();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Face Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. Alice)'),
              ),
              TextField(
                controller: _relationController,
                decoration: const InputDecoration(labelText: 'Relationship (e.g. Daughter)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveFace(pickedFile!);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveFace(XFile imageFile) async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      if (widget.patientId == null) throw Exception('Patient ID is missing');
      final pId = widget.patientId!; 

      // 1. Detect Face & Generate Embedding
      final recogService = ref.read(faceRecognitionServiceProvider);
      // Removed InputImage usage
      List<double> embedding = [];
      
      try {
         final faces = await recogService.detectFaces(imageFile);
         if (faces.isNotEmpty) {
           embedding = await recogService.generateEmbedding(faces.first.alignedFace);
         }
      } catch (e) {
        // If detection crashes, we treat it as no face found
        print("Face detection error: $e");
      }

      if (embedding.isEmpty) {
         // Ask for confirmation
         final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Face Detected'),
              content: const Text('The app could not clearly see a face in this photo.\n\nYou can still save it for the gallery, but the "Who is this?" feature might not recognize this person.\n\nSave anyway?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save Anyway')),
              ],
            ),
         );

         if (confirm != true) {
            setState(() => _isUploading = false);
            return;
         }
      }

      // 2. Save to Firestore
      await ref.read(faceServiceProvider).addFace(
        patientId: pId,
        imageFile: imageFile,
        name: _nameController.text,
        relationship: _relationController.text,
        embedding: embedding,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face Saved Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save Failed: $msg'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.patientId == null) return const Scaffold(body: Center(child: Text('Error: No Patient Selected')));
    
    final pId = widget.patientId!; 
    final faceService = ref.watch(faceServiceProvider);
    
    // Check if current user is the patient (View Only Mode)
    final currentUser = FirebaseAuth.instance.currentUser;
    final isPatientView = currentUser?.uid == pId;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPatientView ? 'Face Gallery' : 'Manage Faces'),
        actions: [
          if (!isPatientView)
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _isUploading ? null : _showAddSourceChoice,
              tooltip: 'Add face (camera or device)',
            ),
        ],
      ),
      floatingActionButton: isPatientView ? null : FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showAddSourceChoice,
        icon: _isUploading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_a_photo),
        label: const Text('Add face'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: faceService.getFaces(pId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
             final errorStr = snapshot.error.toString();
             final isBuilding = errorStr.toLowerCase().contains('building');
             if (isBuilding) {
               return const Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     CircularProgressIndicator(),
                     SizedBox(height: 16),
                     Text('Setting up Face Database...'),
                     Text('Please wait a few minutes.', style: TextStyle(color: Colors.grey)),
                   ],
                 ),
               );
             }
             return Center(child: Text('Error loading faces: $errorStr'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final faces = snapshot.data!.docs;

          if (faces.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isPatientView ? 'No photos added yet.' : 'No faces added yet.', style: const TextStyle(fontSize: 18)),
                  if (!isPatientView) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _showAddSourceChoice,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add face (camera or device)'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                    ),
                  ],
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: faces.length,
            itemBuilder: (context, index) {
              final data = faces[index].data() as Map<String, dynamic>;
              final base64Image = data['image_base64'] as String?;
              final name = data['name'] ?? 'Unknown';
              final relation = data['relationship'] ?? '';

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if (base64Image != null)
                      Image.memory(
                        base64Decode(base64Image),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      )
                    else
                      const Center(child: Icon(Icons.person, size: 50)),
                    
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(relation, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (!isPatientView)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                             // Confirm delete
                             final confirm = await showDialog<bool>(
                               context: context,
                               builder: (context) => AlertDialog(
                                 title: const Text('Delete Face?'),
                                 actions: [
                                   TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                   TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                                 ],
                               ),
                             );
                             
                             if (confirm == true) {
                               await faceService.deleteFace(faces[index].id); // No URL needed now
                             }
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
