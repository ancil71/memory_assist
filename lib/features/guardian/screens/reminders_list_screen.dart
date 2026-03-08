import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';
import 'package:memory_assist/features/guardian/screens/add_reminder_screen.dart';
import 'package:memory_assist/features/guardian/screens/edit_reminder_screen.dart';

/// Guardian screen: view all reminders for a patient, see completion status, add/edit/delete/reorder.
class RemindersListScreen extends ConsumerWidget {
  final String patientId;

  const RemindersListScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderService = ref.watch(reminderServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Reminders'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddReminderScreen(patientId: patientId),
                ),
              );
            },
            tooltip: 'Add Reminder',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: reminderService.getReminders(patientId),
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
                    Text('Error: $err', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    if (isIndex) const SizedBox(height: 16),
                    if (isIndex) const Text('Create the Firestore index (see Firebase Console).', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
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
                  Icon(Icons.alarm_add, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No reminders yet.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddReminderScreen(patientId: patientId)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add first reminder'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'Untitled';
              final type = data['type'] as String? ?? 'other';
              final isCompleted = data['is_completed'] as bool? ?? false;
              final time = data['time'] is Timestamp ? (data['time'] as Timestamp).toDate() : null;
              final timeStr = time != null ? DateFormat('MMM d, h:mm a').format(time) : 'No time';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green : Colors.orange.shade100,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.schedule,
                      color: isCompleted ? Colors.white : Colors.orange,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text('$timeStr • ${type.toString().toUpperCase()}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditReminderScreen(
                              reminderId: doc.id,
                              patientId: patientId,
                              initialTitle: title,
                              initialType: type,
                              initialTime: time ?? DateTime.now(),
                              initialRepeat: data['repeat'] as String? ?? 'daily',
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete reminder?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirm == true) await reminderService.deleteReminder(doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddReminderScreen(patientId: patientId)),
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
