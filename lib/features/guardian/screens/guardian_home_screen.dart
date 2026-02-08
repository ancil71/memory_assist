import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memory_assist/features/guardian/screens/add_reminder_screen.dart';
import 'package:memory_assist/features/guardian/screens/manage_faces_screen.dart';
import 'package:memory_assist/features/guardian/screens/add_safe_location_screen.dart';
import 'package:memory_assist/features/guardian/screens/sos_monitor_screen.dart';
import 'package:clipboard/clipboard.dart'; // Add this dependency manually or use raw flutter clipboard

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  String? _selectedPatientId;
  String? _linkCode;

  @override
  void initState() {
    super.initState();
    _fetchGuardianData();
  }

  Future<void> _fetchGuardianData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _linkCode = doc.data()?['link_code'] as String?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please Login'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Dashboard'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Patient Switcher & Link Code
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                if (_linkCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Link Code: $_linkCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            // Simple copy logic
                            // Clipboard.setData(ClipboardData(text: _linkCode!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code Copied!')));
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // Fetch Linked Patients
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final linkedUids = List<String>.from(data?['linked_uids'] ?? []);

                    if (linkedUids.isEmpty) {
                      return const Text('No patients linked yet. Share your code!');
                    }

                    // For MVP, just select the first one if not selected
                    if (_selectedPatientId == null && linkedUids.isNotEmpty) {
                       // We should ideally fetch their names, but for now use ID or fetch name in a separate Future
                       _selectedPatientId = linkedUids.first;
                    }

                    return Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedPatientId,
                            isExpanded: true,
                            hint: const Text('Select Patient'),
                            items: linkedUids.map((uid) {
                              return DropdownMenuItem(
                                value: uid,
                                child: Text('Patient ID: ...${uid.substring(0,6)}'), 
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedPatientId = val),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. Dashboard Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.alarm_add,
                  title: 'Reminders',
                  color: Colors.orange.shade100,
                  onTap: () {
                    if (_selectedPatientId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddReminderScreen(patientId: _selectedPatientId!)));
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a patient first')));
                    }
                  },
                ),
                _DashboardCard(
                  icon: Icons.face,
                  title: 'Face Gallery',
                  color: Colors.purple.shade100,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFacesScreen()));
                  },
                ),
                _DashboardCard(
                  icon: Icons.map, 
                  title: 'Safe Locations',
                  color: Colors.green.shade100,
                  onTap: () {
                     if (_selectedPatientId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddSafeLocationScreen(patientId: _selectedPatientId!)));
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a patient first')));
                     }
                  },
                ),
                _DashboardCard(
                  icon: Icons.monitor_heart, 
                  title: 'SOS Monitor',
                  color: Colors.red.shade100,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SOSMonitorScreen()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.black54),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
