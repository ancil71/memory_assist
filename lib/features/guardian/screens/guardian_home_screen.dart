import 'package:flutter/material.dart';
import 'package:memory_assist/features/guardian/screens/add_reminder_screen.dart';
import 'package:memory_assist/features/guardian/screens/manage_faces_screen.dart';
import 'package:memory_assist/features/guardian/screens/add_safe_location_screen.dart';
import 'package:memory_assist/features/guardian/screens/sos_monitor_screen.dart';

class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // 1. Patient Switcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Managing Patient:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'Mom',
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 'Mom', child: Text('Mom (Alice)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                            DropdownMenuItem(value: 'Dad', child: Text('Dad (Bob)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                          ], 
                          onChanged: (val) {},
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: () {
                    // TODO: Link new patient
                  },
                  tooltip: 'Link new patient',
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
                    // TODO: Pass actual patient ID
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReminderScreen(patientId: 'patient_uid_mock')));
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
                  icon: Icons.map, // or location_on
                  title: 'Safe Locations', // "guardian can add locations"
                  color: Colors.green.shade100,
                  onTap: () {
                     // TODO: Pass actual patient ID
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSafeLocationScreen(patientId: 'patient_uid_mock')));
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
