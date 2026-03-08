import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Short alarm sound URL (CC0 / free to use).
const _kSosAlarmUrl = 'https://assets.mixkit.co/active_storage/sfx/2869-alarm-clock-beep.mp3';

class SOSMonitorScreen extends StatefulWidget {
  const SOSMonitorScreen({super.key});

  @override
  State<SOSMonitorScreen> createState() => _SOSMonitorScreenState();
}

class _SOSMonitorScreenState extends State<SOSMonitorScreen> {
  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _alarmPlayedForCurrentAlerts = false;

  @override
  void dispose() {
    _alarmPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAlarmIfNeeded(int alertCount) async {
    if (alertCount == 0) {
      _alarmPlayedForCurrentAlerts = false;
      try { await _alarmPlayer.stop(); } catch (_) {}
      return;
    }
    if (_alarmPlayedForCurrentAlerts) return;
    _alarmPlayedForCurrentAlerts = true;
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.play(UrlSource(_kSosAlarmUrl));
    } catch (_) {}
  }

  Future<void> _openInMaps(double lat, double lng, [String? placeName]) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            final isIndex = err.contains('failed-precondition');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      isIndex
                          ? 'Database index is building. Wait a few minutes or create the index in Firebase Console.'
                          : 'Error: $err',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!.docs;
          _playAlarmIfNeeded(alerts.length);

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
              final startTime = data['start_time'];
              final timeStr = startTime is Timestamp
                  ? DateFormat('MMM d, h:mm a').format(startTime.toDate())
                  : '$startTime';
              return _SOSAlertCard(
                timeStr: timeStr,
                location: location,
                onViewInMaps: _openInMaps,
              );
            },
          );
        },
      ),
    );
  }
}

class _SOSAlertCard extends StatefulWidget {
  final String timeStr;
  final GeoPoint? location;
  final Future<void> Function(double lat, double lng, [String? placeName]) onViewInMaps;

  const _SOSAlertCard({required this.timeStr, required this.location, required this.onViewInMaps});

  @override
  State<_SOSAlertCard> createState() => _SOSAlertCardState();
}

class _SOSAlertCardState extends State<_SOSAlertCard> {
  String? _placeName;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) _fetchPlaceName();
  }

  Future<void> _fetchPlaceName() async {
    final loc = widget.location;
    if (loc == null) return;
    try {
      final list = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (list.isNotEmpty && mounted) {
        final p = list.first;
        final parts = [p.street, p.locality, p.administrativeArea, p.country].whereType<String>().where((s) => s.isNotEmpty);
        setState(() => _placeName = parts.join(', '));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 40),
                SizedBox(width: 12),
                Text('EMERGENCY ALERT!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Time: ${widget.timeStr}', style: const TextStyle(fontWeight: FontWeight.w500)),
            if (location != null) ...[
              if (_placeName != null) ...[
                const SizedBox(height: 4),
                Text('Place: $_placeName', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 4),
              Text('Coordinates: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.onViewInMaps(location.latitude, location.longitude, _placeName),
                  icon: const Icon(Icons.map),
                  label: const Text('View in Google Maps'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
