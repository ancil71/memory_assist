import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_assist/core/models/user_model.dart';

/// Guardian view: full profile of a connected patient.
class PatientProfileViewScreen extends StatelessWidget {
  final String patientId;

  const PatientProfileViewScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(patientId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: Text('Patient not found'));
          }
          final user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: _buildAvatar(user.profileImageBase64),
              ),
              const SizedBox(height: 24),
              _ProfileRow(label: 'Name', value: user.name ?? 'N/A'),
              _ProfileRow(label: 'Email', value: user.email),
              _ProfileRow(label: 'Phone', value: user.phone ?? '—'),
              _ProfileRow(label: 'Address', value: user.address ?? '—'),
              const Divider(height: 32),
              const Text('Medical', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ProfileRow(label: 'Age', value: user.age?.toString() ?? '—'),
              _ProfileRow(label: 'Blood Group', value: user.bloodGroup ?? '—'),
              _ProfileRow(label: 'Height', value: user.height != null ? '${user.height} cm' : '—'),
              _ProfileRow(label: 'Weight', value: user.weight != null ? '${user.weight} kg' : '—'),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildAvatar(String? base64) {
    if (base64 == null || base64.isEmpty) {
      return CircleAvatar(radius: 50, backgroundColor: Colors.teal.shade100, child: const Icon(Icons.person, size: 50));
    }
    final bytes = _imageBytes(base64);
    if (bytes.isEmpty) {
      return CircleAvatar(radius: 50, backgroundColor: Colors.teal.shade100, child: const Icon(Icons.person, size: 50));
    }
    return CircleAvatar(radius: 50, backgroundImage: MemoryImage(bytes));
  }

  static Uint8List _imageBytes(String base64) {
    try {
      return Uint8List.fromList(base64Decode(base64));
    } catch (_) {
      return Uint8List(0);
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
