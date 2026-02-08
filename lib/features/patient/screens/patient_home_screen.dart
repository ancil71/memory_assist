import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';
import 'package:intl/intl.dart';
import 'package:memory_assist/features/patient/screens/safe_locations_screen.dart';
import 'package:memory_assist/features/auth/services/link_service.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  String? _userId;

  @override
  void initState() {
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _userId = FirebaseAuth.instance.currentUser?.uid;
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = _formatTime(now);
      _dateString = _formatDate(now);
    });
  }

  String _formatTime(DateTime dateTime) => DateFormat('hh:mm a').format(dateTime);
  String _formatDate(DateTime dateTime) => DateFormat('EEEE, MMMM d').format(dateTime);

  void _showLinkDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect to Guardian'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Enter 6-digit Code'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_userId == null) return;
              final success = await ref.read(linkServiceProvider).linkPatientToGuardian(_userId!, controller.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Connected Successfully!' : 'Invalid Code')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const Scaffold(body: Center(child: Text('Loading User...')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Memory Assist', style: TextStyle(color: Colors.white, fontSize: 28)),
        backgroundColor: const Color(0xFF0055FF),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.white, size: 32),
            onPressed: _showLinkDialog,
            tooltip: 'Link to Guardian',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 32),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if(mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Digital Clock
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            color: const Color(0xFFE3F2FD),
            child: Column(
              children: [
                Text(_timeString, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black)),
                Text(_dateString, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 2, thickness: 2, color: Colors.black),

          // 2. My Tasks (Realtime)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final reminderService = ref.watch(reminderServiceProvider);

                return StreamBuilder<QuerySnapshot>(
                  stream: reminderService.getReminders(_userId!),
                  builder: (context, snapshot) {
                     if (snapshot.hasError) return const Center(child: Text('Error loading tasks'));
                     if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final reminders = snapshot.data!.docs;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'MY TASKS',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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

          // 3. Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0055FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Camera for Face ID...')));
                      },
                      icon: const Icon(Icons.camera_alt, size: 48, color: Colors.white),
                      label: const Text('WHO IS THIS?', style: TextStyle(fontSize: 24, color: Colors.white), textAlign: TextAlign.center),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFCC00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SafeLocationsScreen(patientId: _userId!))),
                      icon: const Icon(Icons.map, size: 48, color: Colors.black),
                      label: const Text('MY PLACES', style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 100,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                    // Trigger SOS logic
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS TRIGGERED!')));
                },
                icon: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                label: const Text('SOS HELP', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
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
                    fontSize: 24,
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
