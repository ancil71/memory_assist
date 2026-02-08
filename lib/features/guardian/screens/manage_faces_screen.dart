import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/face_service.dart';

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

  Future<void> _addFace() async {
    // 1. Pick Image
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress to avoid Firestore 1MB limit
      maxWidth: 600,
    );
    
    if (pickedFile == null) return;
    if (!mounted) return;

    // 2. Dialog for Name & Relationship
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
              onPressed: () => Navigator.pop(context), // Cancel
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog verify inputs later
                _saveFace(File(pickedFile.path));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveFace(File imageFile) async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      // Use provided patientId or default for standalone testing
      final pId = widget.patientId ?? 'patient_uid_mock'; 

      await ref.read(faceServiceProvider).addFace(
        patientId: pId,
        imageFile: imageFile,
        name: _nameController.text,
        relationship: _relationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Face Saved Successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use provided patientId or default
    final pId = widget.patientId ?? 'patient_uid_mock'; 
    final faceService = ref.watch(faceServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faces')),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _addFace,
        child: _isUploading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Icon(Icons.add_a_photo),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: faceService.getFaces(pId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading faces'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final faces = snapshot.data!.docs;

          if (faces.isEmpty) {
            return const Center(child: Text('No faces added yet.'));
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
