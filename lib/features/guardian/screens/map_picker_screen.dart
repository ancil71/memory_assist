import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of picking a location on the map: lat, lng, and resolved address.
class MapPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  const MapPickerResult({required this.latitude, required this.longitude, required this.address});
}

/// Full-screen map. User taps to set a marker; we reverse-geocode to get address and return result.
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  LatLng? _selected;
  String? _address;
  bool _loading = false;
  static const _defaultCenter = LatLng(10.0, 76.3);

  LatLng get _initial => (widget.initialLat != null && widget.initialLng != null)
      ? LatLng(widget.initialLat!, widget.initialLng!)
      : _defaultCenter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _loading = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        // ignore: unnecessary_null_comparison
        if (loc == null) throw Exception("Location found but data is null");
        
        final latLng = LatLng(loc.latitude, loc.longitude);
        
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
        _onMapTap(latLng); // Select found location
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not found')));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selected = position;
      _address = null;
      _loading = true;
    });
    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted) {
        final p = placemarks.isNotEmpty ? placemarks.first : null;
        final parts = p != null
            ? [p.street, p.subLocality, p.locality, p.administrativeArea, p.country]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
            : <String>[];
        setState(() {
          _address = parts.isNotEmpty ? parts.join(', ') : '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
          _loading = false;
        });
      }
    }
  }

  void _confirm() {
    if (_selected == null) return;
    Navigator.pop(context, MapPickerResult(
      latitude: _selected!.latitude,
      longitude: _selected!.longitude,
      address: _address ?? '${_selected!.latitude}, ${_selected!.longitude}',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: _loading ? null : _confirm,
              child: const Text('Use this location'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initial, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTap,
            markers: _selected != null
                ? {Marker(markerId: const MarkerId('picked'), position: _selected!)}
                : {},
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            padding: const EdgeInsets.only(top: 80), // Avoid search bar overlap
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search location (e.g. Paris, Home)',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _searchLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const Center(child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting address...'),
                  ],
                ),
              ),
            )),
          if (_address != null && !_loading)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_address!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _confirm,
                        child: const Text('Use this location'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
