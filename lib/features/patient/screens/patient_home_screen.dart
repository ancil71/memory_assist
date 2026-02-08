import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';
import 'package:intl/intl.dart';
import 'package:memory_assist/features/patient/screens/safe_locations_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;

  @override
  void initState() {
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = _formatTime(now);
    final String formattedDate = _formatDate(now);
    setState(() {
      _timeString = formattedTime;
      _dateString = formattedDate;
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMMM d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    // Accessibility: High contrast colors
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Memory Assist', style: TextStyle(color: Colors.white, fontSize: 28)),
        backgroundColor: const Color(0xFF0055FF), // High contrast Blue
        centerTitle: true,
        automaticallyImplyLeading: false, // Hide back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 32),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Digital Clock & Date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            color: const Color(0xFFE3F2FD),
            child: Column(
              children: [
                Text(
                  _timeString,
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _dateString,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 2, thickness: 2, color: Colors.black),

          // 2. My Tasks (Realtime Stream)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final reminderService = ref.watch(reminderServiceProvider);
                // TODO: Use actual logged in patient ID
                const patientId = 'patient_uid_mock'; 

                return StreamBuilder<QuerySnapshot>(
                  stream: reminderService.getReminders(patientId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const Text('Something went wrong');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reminders = snapshot.data!.docs;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'MY TASKS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (reminders.isEmpty)
                          const Text('No tasks for today!', style: TextStyle(fontSize: 20)),
                        
                        ...reminders.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _TaskItem(
                            id: doc.id,
                            label: data['title'] ?? 'Unknown Task',
                            isCompleted: data['is_completed'] ?? false,
                            onToggle: (val) {
                               reminderService.toggleCompletion(doc.id, val);
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 3. Actions (Face Rec & SOS)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Face Recognition Button
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0055FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                         // TODO: Navigate to Face Recognition Screen
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Opening Camera for Face ID...')),
                         );
                      },
                      icon: const Icon(Icons.camera_alt, size: 48, color: Colors.white),
                      label: const Text(
                        'WHO IS THIS?',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Places Button
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00), // Yellow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => const SafeLocationsScreen()),
                         );
                      },
                      icon: const Icon(Icons.map, size: 48, color: Colors.black),
                      label: const Text(
                        'MY PLACES',
                        style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // SOS Button (Full Width at Bottom)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 100, // Large SOS button
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F), // Red
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                    // TODO: Trigger SOS
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SOS TRIGGERED!')),
                    );
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                label: const Text(
                  'SOS HELP',
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String id;
  final String label;
  final bool isCompleted;
  final Function(bool) onToggle;

  const _TaskItem({required this.id, required this.label, required this.isCompleted, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => onToggle(!isCompleted),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade100 : Colors.grey.shade100,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Transform.scale(
                scale: 2.0,
                child: Checkbox(
                  value: isCompleted,
                  activeColor: Colors.green,
                  onChanged: (v) => onToggle(v!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 24, // Large text
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
