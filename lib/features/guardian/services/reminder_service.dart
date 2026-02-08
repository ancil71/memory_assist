import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reminderServiceProvider = Provider((ref) => ReminderService());

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add Reminder
  Future<void> addReminder({
    required String patientId,
    required String creatorId,
    required String title,
    required String type, // 'medication' | 'appointment' | 'other'
    required DateTime time,
    required String repeat, // 'daily' | 'weekly' | 'none'
  }) async {
    await _firestore.collection('reminders').add({
      'patient_id': patientId,
      'creator_id': creatorId,
      'title': title,
      'type': type,
      'time': Timestamp.fromDate(time),
      'is_completed': false,
      'repeat': repeat,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Get Stream of Reminders for a Patient
  Stream<QuerySnapshot> getReminders(String patientId) {
    return _firestore
        .collection('reminders')
        .where('patient_id', isEqualTo: patientId)
        .orderBy('time', descending: false)
        .snapshots();
  }

  // Mark as Completed
  Future<void> toggleCompletion(String reminderId, bool isCompleted) async {
    await _firestore.collection('reminders').doc(reminderId).update({
      'is_completed': isCompleted,
    });
  }

  // Delete Reminder
  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).delete();
  }
}
