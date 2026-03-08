import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_assist/features/patient/screens/safe_locations_screen.dart';
import 'package:memory_assist/features/auth/screens/role_selection_screen.dart';
import 'package:memory_assist/features/auth/services/link_service.dart';
import 'package:memory_assist/features/patient/screens/face_scan_screen.dart';
import 'package:memory_assist/features/profile/screens/profile_screen.dart';
import 'package:memory_assist/features/settings/screens/settings_screen.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';
import 'package:memory_assist/features/patient/services/sos_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

const _kOverdueAlarmUrl = 'https://assets.mixkit.co/active_storage/sfx/995-classic-alarm.mp3';

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  late String _timeString;
  late String _dateString;
  late Timer _timer;
  String? _userId;
  bool _overdueAlarmPlayed = false;
  final AudioPlayer _overduePlayer = AudioPlayer();

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    _timeString = _formatTime(DateTime.now());
    _dateString = _formatDate(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
    _userId = FirebaseAuth.instance.currentUser?.uid;
    super.initState();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position? position) {
          if (position != null && _userId != null) {
            FirebaseFirestore.instance.collection('users').doc(_userId).update({
              'current_location': GeoPoint(position.latitude, position.longitude),
              'last_updated': FieldValue.serverTimestamp(),
            });
          }
        },
        onError: (_) {},
      );
    } catch (_) {
      // Location may be unavailable on web or denied
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _positionStream?.cancel();
    _overduePlayer.dispose();
    super.dispose();
  }

  void _playOverdueAlarmOnce() {
    if (_overdueAlarmPlayed) return;
    _overdueAlarmPlayed = true;
    _overduePlayer.play(UrlSource(_kOverdueAlarmUrl)).catchError((_) {});
  }

  void _getTime() {
    final DateTime now = DateTime.now();
    final String newTime = _formatTime(now);
    final String newDate = _formatDate(now);
    // Only rebuild when time or date string changes to avoid glitching
    if (newTime != _timeString || newDate != _dateString) {
      setState(() {
        _timeString = newTime;
        _dateString = newDate;
      });
    }
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
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.link, color: Colors.white, size: 28),
            onPressed: _showLinkDialog,
            tooltip: 'Link to Guardian',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                (route) => false,
              );
            },
          ),
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
                     if (snapshot.hasError) {
                       final errorStr = snapshot.error.toString();
                       final isIndexError = errorStr.contains('failed-precondition');
                       final isBuilding = errorStr.toLowerCase().contains('building');
                       
                       return Center(child: Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             if (isBuilding) ...[
                                const Icon(Icons.sync, size: 50, color: Colors.blue),
                                const SizedBox(height: 16),
                                const Text('Database is setting up...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text('This usually takes 5-10 minutes. The app will update automatically when ready.', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                             ] else ...[
                               Text('Error: $errorStr', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                               if (isIndexError) ...[
                                 const SizedBox(height: 16),
                                 ElevatedButton.icon(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                   icon: const Icon(Icons.build),
                                   label: const Text('CREATE DATABASE INDEX (REQUIRED)'),
                                   onPressed: () async {
                                      // Extract URL
                                      final RegExp urlRegExp = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
                                      final match = urlRegExp.firstMatch(errorStr);
                                      if (match != null) {
                                        final url = Uri.parse(match.group(0)!);
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      }
                                   },
                                 ),
                                 const Text('(Click above -> Click "Create Index" -> Wait 5 mins)', style: TextStyle(color: Colors.grey)),
                               ]
                             ]
                           ],
                         ),
                       ));
                     }
                     if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final reminders = snapshot.data!.docs;
                    final now = DateTime.now();
                    final overdue = reminders.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      if (d['is_completed'] == true) return false;
                      final t = d['time'];
                      final taskTime = t is Timestamp ? t.toDate() : null;
                      return taskTime != null && taskTime.isBefore(now);
                    }).toList();
                    if (overdue.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _playOverdueAlarmOnce();
                      });
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'MY TASKS',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                        if (overdue.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Material(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.notifications_active, color: Colors.orange.shade800),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${overdue.length} overdue task(s) — complete them below.',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (reminders.isEmpty)
                          const Text('No tasks for today!', style: TextStyle(fontSize: 20)),
                        
                        ...reminders.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final timeStamp = data['time'];
                          final taskTime = timeStamp is Timestamp ? timeStamp.toDate() : null;
                          return _TaskItem(
                            id: doc.id,
                            label: data['title'] ?? 'Unknown Task',
                            isCompleted: data['is_completed'] ?? false,
                            taskTime: taskTime,
                            onToggle: (val) {
                               reminderService.toggleCompletion(doc.id, val);
                            },
                          );
                        }),
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
            child: Column(
              children: [
                // Connect Banner if not linked (mock check for now, ideally stream user doc)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(_userId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    final linkedUids = List.from(data?['linked_uids'] ?? []);
                    
                    if (linkedUids.isNotEmpty) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _showLinkDialog,
                        icon: const Icon(Icons.link, size: 32),
                        label: const Text('CONNECT TO GUARDIAN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),

                Row(
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
                             if (_userId != null) {
                               // Open Camera Scanner (Simulated ML)
                               Navigator.push(context, MaterialPageRoute(builder: (_) => FaceScanScreen(patientId: _userId!)));
                             }
                          },
                          icon: const Icon(Icons.camera_alt, size: 48, color: Colors.white),
                          label: const Text('WHO IS THIS?\n(Scan Face)', style: TextStyle(fontSize: 20, color: Colors.white), textAlign: TextAlign.center),
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
                onPressed: () async {
                    try {
                      await ref.read(sosServiceProvider).triggerSOS(_userId!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SOS sent! Your guardian will see your location.'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('SOS failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
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
  final DateTime? taskTime;
  final Function(bool) onToggle;

  const _TaskItem({
    required this.id,
    required this.label,
    required this.isCompleted,
    this.taskTime,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = taskTime != null ? DateFormat('h:mm a').format(taskTime!) : null;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (timeStr != null)
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
