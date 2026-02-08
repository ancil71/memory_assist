import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ManageFacesScreen extends StatefulWidget {
  const ManageFacesScreen({super.key});

  @override
  State<ManageFacesScreen> createState() => _ManageFacesScreenState();
}

class _ManageFacesScreenState extends State<ManageFacesScreen> {
  final _picker = ImagePicker();
  List<File> _faces = []; // Local placeholder list

  Future<void> _addFace() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _faces.add(File(pickedFile.path));
      });
      // TODO: Upload to Firebase Storage and update Firestore 'faces' collection
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faces')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFace,
        child: const Icon(Icons.add_a_photo),
      ),
      body: _faces.isEmpty
          ? const Center(child: Text('No faces added yet.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _faces.length,
              itemBuilder: (context, index) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.file(
                        _faces[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: const Text(
                            'Unknown', // Placeholder Name
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
