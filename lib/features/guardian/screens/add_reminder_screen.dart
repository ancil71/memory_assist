import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';

class AddReminderScreen extends ConsumerStatefulWidget {
  final String patientId;

  const AddReminderScreen({super.key, required this.patientId});

  @override
  ConsumerState<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends ConsumerState<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _type = 'medication';
  String _repeat = 'daily';

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final creatorId = FirebaseAuth.instance.currentUser?.uid;
      if (creatorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in again.')));
        return;
      }
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      ref.read(reminderServiceProvider).addReminder(
        patientId: widget.patientId,
        creatorId: creatorId,
        title: _titleController.text,
        type: _type,
        time: dateTime,
        repeat: _repeat,
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Reminder Title'),
                validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'medication', child: Text('Medication')),
                  DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _type = val ?? 'medication'),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _repeat,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Once')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (val) => setState(() => _repeat = val ?? 'daily'),
                decoration: const InputDecoration(labelText: 'Repeat'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Time: ${DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute)
                )}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
