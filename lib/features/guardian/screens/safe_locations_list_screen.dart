import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_assist/features/guardian/services/safe_locations_service.dart';
import 'package:memory_assist/features/guardian/screens/add_safe_location_screen.dart';

class SafeLocationsListScreen extends ConsumerWidget {
  final String patientId;

  const SafeLocationsListScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationService = ref.watch(safeLocationsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Locations'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddSafeLocationScreen(patientId: patientId),
            ),
          );
        },
        child: const Icon(Icons.add_location_alt),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: locationService.getLocations(patientId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.location_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('No safe locations added yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                   const SizedBox(height: 16),
                   ElevatedButton.icon(
                     onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddSafeLocationScreen(patientId: patientId),
                          ),
                        );
                     }, 
                     icon: const Icon(Icons.add), 
                     label: const Text('Add First Location')
                   ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              final name = data['name'] ?? 'Unknown';
              final address = data['address'] ?? '';
              final geoPoint = data['coordinates'] as GeoPoint?;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddSafeLocationScreen(
                                patientId: patientId,
                                locationId: id,
                                initialName: name,
                                initialAddress: address,
                                initialLat: geoPoint?.latitude,
                                initialLng: geoPoint?.longitude,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Location?'),
                              content: Text('Are you sure you want to delete "$name"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await locationService.deleteLocation(id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
