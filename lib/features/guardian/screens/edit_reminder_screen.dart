import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:memory_assist/features/guardian/services/reminder_service.dart';

class EditReminderScreen extends ConsumerStatefulWidget {
  final String reminderId;
  final String patientId;
  final String initialTitle;
  final String initialType;
  final DateTime initialTime;
  final String initialRepeat;

  const EditReminderScreen({
    super.key,
    required this.reminderId,
    required this.patientId,
    required this.initialTitle,
    required this.initialType,
    required this.initialTime,
    required this.initialRepeat,
  });

  @override
  ConsumerState<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends ConsumerState<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _type;
  late String _repeat;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedDate = widget.initialTime;
    _selectedTime = TimeOfDay.fromDateTime(widget.initialTime);
    _type = widget.initialType;
    _repeat = widget.initialRepeat;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(context: context, initialTime: _selectedTime);
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    await ref.read(reminderServiceProvider).updateReminder(
          reminderId: widget.reminderId,
          title: _titleController.text.trim(),
          type: _type,
          time: dateTime,
          repeat: _repeat,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Reminder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Reminder Title'),
                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
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
                title: Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime(
                    _selectedDate.year, _selectedDate.month, _selectedDate.day,
                    _selectedTime.hour, _selectedTime.minute))),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
