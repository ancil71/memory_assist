import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SOSMonitorScreen extends StatelessWidget {
  const SOSMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS Monitor'), backgroundColor: Colors.red),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_events')
            .where('is_active', isEqualTo: true)
            .orderBy('start_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error monitoring SOS'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All Clear. No Active SOS.', style: TextStyle(fontSize: 24)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              final location = data['location'] as GeoPoint?;
              
              return Card(
                color: Colors.red.shade50,
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red, size: 40),
                  title: const Text('EMERGENCY ALERT!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: Text('Location: ${location?.latitude}, ${location?.longitude}\nTime: ${data['start_time'].toDate()}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to map / Resolve alert
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('VIEW'),
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
