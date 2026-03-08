import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memory_assist/features/guardian/screens/reminders_list_screen.dart';
import 'package:memory_assist/features/guardian/screens/manage_faces_screen.dart';
import 'package:memory_assist/features/guardian/screens/safe_locations_list_screen.dart';
import 'package:memory_assist/features/guardian/screens/sos_monitor_screen.dart';
import 'package:memory_assist/features/guardian/screens/live_tracking_screen.dart';
import 'package:memory_assist/features/profile/screens/profile_screen.dart';
import 'package:memory_assist/features/profile/screens/patient_profile_view_screen.dart';
import 'package:memory_assist/features/settings/screens/settings_screen.dart';
import 'package:flutter/services.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  String? _selectedPatientId;
  String? _linkCode;
  
  // SOS Alarm
  final AudioPlayer _sosPlayer = AudioPlayer();
  StreamSubscription<DocumentSnapshot>? _sosSubscription;
  bool _isSosDialogShowing = false;

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

  Future<void> _generateLinkCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Generate simple 6-char code using Random
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rng = Random();
      final newCode = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'link_code': newCode});
      setState(() => _linkCode = newCode);
    }
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    _sosPlayer.dispose();
    super.dispose();
  }

  void _listenToSos(String patientId) {
    _sosSubscription?.cancel();
    _sosSubscription = FirebaseFirestore.instance.collection('users').doc(patientId).snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final isSos = data['sos_active'] == true;
      
      if (isSos && !_isSosDialogShowing) {
        _triggerSosAlarm();
      } else if (!isSos && _isSosDialogShowing) {
        // Dismiss if SOS cleared remotely
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> _triggerSosAlarm() async {
    _isSosDialogShowing = true;
    try {
      await _sosPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2190-emergency-alarm-siren.mp3'));
    } catch (e) {
      print("Error playing SOS sound: $e");
    }
    
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('SOS ALERT!')]),
        content: const Text('The patient has triggered an SOS alarm! Check their location immediately.'),
        actions: [
          TextButton(
            onPressed: () {
              _sosPlayer.stop();
              _isSosDialogShowing = false;
              Navigator.pop(context);
              // Navigate to Live Tracking
              if (_selectedPatientId != null) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingScreen(patientId: _selectedPatientId!)));
              }
            },
            child: const Text('View Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
               _sosPlayer.stop();
               _isSosDialogShowing = false;
               Navigator.pop(context);
            }, 
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
    _isSosDialogShowing = false;
    _sosPlayer.stop();
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
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
                            if (_linkCode != null) {
                              Clipboard.setData(ClipboardData(text: _linkCode!));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code Copied!')));
                            }
                          },
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _generateLinkCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate Link Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(height: 16),
                
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final linkedUids = List<String>.from(data?['linked_uids'] ?? []);

                    if (linkedUids.isEmpty) {
                      return const Text('No patients linked yet. Share your code!');
                    }

                    if (_selectedPatientId == null && linkedUids.isNotEmpty) {
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _selectedPatientId == null) {
                             setState(() {
                                _selectedPatientId = linkedUids.first;
                                _listenToSos(linkedUids.first);
                             });
                          }
                       });
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where(FieldPath.documentId, whereIn: linkedUids.take(10).toList())
                          .snapshots(),
                      builder: (context, patientsSnapshot) {
                         if (!patientsSnapshot.hasData) return const LinearProgressIndicator();

                         final patientDocs = patientsSnapshot.data!.docs;
                         
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                                 const SizedBox(width: 16),
                                 Expanded(
                                   child: DropdownButton<String>(
                                     value: _selectedPatientId,
                                     isExpanded: true,
                                     hint: const Text('Select Patient'),
                                     items: patientDocs.map((doc) {
                                       final pData = doc.data() as Map<String, dynamic>;
                                       final name = pData['name'] ?? 'Patient ...${doc.id.substring(doc.id.length - 4)}';
                                       return DropdownMenuItem(
                                         value: doc.id,
                                         child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                       );
                                     }).toList(),
                                     onChanged: (val) {
                                       setState(() => _selectedPatientId = val);
                                       if (val != null) _listenToSos(val);
                                     },
                                   ),
                                 ),
                                 if (_selectedPatientId != null)
                                   IconButton(
                                     icon: const Icon(Icons.info_outline),
                                     tooltip: 'View patient profile',
                                     onPressed: () => Navigator.push(
                                       context,
                                       MaterialPageRoute(
                                         builder: (_) => PatientProfileViewScreen(patientId: _selectedPatientId!),
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           ],
                         );
                      },
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RemindersListScreen(patientId: _selectedPatientId!)));
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
                    if (_selectedPatientId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ManageFacesScreen(patientId: _selectedPatientId!)));
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a patient first')));
                    }
                  },
                ),
                _DashboardCard(
                  icon: Icons.map, 
                  title: 'Safe Locations',
                  color: Colors.green.shade100,
                  onTap: () {
                     if (_selectedPatientId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => SafeLocationsListScreen(patientId: _selectedPatientId!)));
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
                _DashboardCard(
                  icon: Icons.location_searching, 
                  title: 'Live Tracking',
                  color: Colors.blue.shade100,
                  onTap: () {
                    if (_selectedPatientId != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingScreen(patientId: _selectedPatientId!)));
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a patient first')));
                    }
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
