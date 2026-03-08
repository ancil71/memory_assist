import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/screens/map_picker_screen.dart';
import 'package:memory_assist/features/guardian/services/safe_locations_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddSafeLocationScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? locationId;
  final String? initialName;
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const AddSafeLocationScreen({
    super.key,
    required this.patientId,
    this.locationId,
    this.initialName,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  ConsumerState<AddSafeLocationScreen> createState() => _AddSafeLocationScreenState();
}

class _AddSafeLocationScreenState extends ConsumerState<AddSafeLocationScreen> {
  final _nameController = TextEditingController();
  double? _pickedLat;
  double? _pickedLng;
  String? _pickedAddress;

  @override
  void initState() {
    super.initState();
    if (widget.locationId != null) {
      _nameController.text = widget.initialName ?? '';
      _pickedLat = widget.initialLat;
      _pickedLng = widget.initialLng;
      _pickedAddress = widget.initialAddress;
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _pickedLat,
          initialLng: _pickedLng,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
        _pickedAddress = result.address;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a location name (e.g. Home)')));
      return;
    }
    if (_pickedLat == null || _pickedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick the location on the map first')));
      return;
    }
    
    final service = ref.read(safeLocationsServiceProvider);
    
    if (widget.locationId != null) {
      await service.updateLocation(
        locationId: widget.locationId!,
        name: _nameController.text.trim(),
        address: _pickedAddress ?? '',
        latitude: _pickedLat!,
        longitude: _pickedLng!,
      );
    } else {
      await service.addLocation(
        patientId: widget.patientId,
        name: _nameController.text.trim(),
        address: _pickedAddress ?? '',
        latitude: _pickedLat!,
        longitude: _pickedLng!,
      );
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.locationId != null ? 'Edit Location' : 'Add Safe Location')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose the place on the map, then give it a name.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name (e.g. Home)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map),
                label: Text(_pickedAddress != null ? 'Change location on map' : 'Pick location on Google Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
              if (_pickedLat != null && _pickedLng != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 200, 
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_pickedLat!, _pickedLng!),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('preview'),
                          position: LatLng(_pickedLat!, _pickedLng!),
                        ),
                      },
                      liteModeEnabled: true,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      onTap: (_) => _pickOnMap(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected address:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_pickedAddress!, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.locationId != null ? 'Update Location' : 'Save Location'),
            ),
          ],
        ),
      ),
    );
  }
}
