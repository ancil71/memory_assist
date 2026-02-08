import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/safe_locations_service.dart';

class AddSafeLocationScreen extends ConsumerStatefulWidget {
  final String patientId;

  const AddSafeLocationScreen({super.key, required this.patientId});

  @override
  ConsumerState<AddSafeLocationScreen> createState() => _AddSafeLocationScreen();
}

class _AddSafeLocationScreen extends ConsumerState<AddSafeLocationScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  Future<void> _submit() async {
    if (_nameController.text.isNotEmpty && _latController.text.isNotEmpty) {
      await ref.read(safeLocationsServiceProvider).addLocation(
        patientId: widget.patientId,
        name: _nameController.text,
        address: _addressController.text,
        latitude: double.tryParse(_latController.text) ?? 0.0,
        longitude: double.tryParse(_lngController.text) ?? 0.0,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Safe Location')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Location Name (e.g. Home)'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            // In a real app, use Google Maps Place Picker
            TextField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Latitude (Mock)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lngController,
              decoration: const InputDecoration(labelText: 'Longitude (Mock)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save Location'),
            ),
          ],
        ),
      ),
    );
  }
}
