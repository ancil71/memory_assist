import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_assist/core/models/user_model.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  String? _selectedBloodGroup;
  bool _isLoading = false;
  bool _pickingImage = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _ageController = TextEditingController(text: widget.user.age?.toString() ?? '');
    _heightController = TextEditingController(text: widget.user.height?.toString() ?? '');
    _weightController = TextEditingController(text: widget.user.weight?.toString() ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _selectedBloodGroup = widget.user.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _profileImageBase64;

  Future<void> _pickProfileImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() => _profileImageBase64 = base64Encode(bytes));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      };
      if (_profileImageBase64 != null) updates['profile_image_base64'] = _profileImageBase64;

      if (widget.user.role == 'patient') {
        if (_ageController.text.isNotEmpty) updates['age'] = int.tryParse(_ageController.text);
        if (_heightController.text.isNotEmpty) updates['height'] = double.tryParse(_heightController.text);
        if (_weightController.text.isNotEmpty) updates['weight'] = double.tryParse(_weightController.text);
        if (_selectedBloodGroup != null) updates['blood_group'] = _selectedBloodGroup;
      }

      await ref.read(authServiceProvider).updateUser(widget.user.uid, updates);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
      Navigator.pop(context, true); // Return true to indicate update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian = widget.user.role == 'guardian';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickingImage ? null : _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  backgroundImage: _profileImageBase64 != null
                      ? MemoryImage(base64Decode(_profileImageBase64!))
                      : (widget.user.profileImageBase64 != null && widget.user.profileImageBase64!.isNotEmpty
                          ? MemoryImage(base64Decode(widget.user.profileImageBase64!))
                          : null),
                  child: _profileImageBase64 == null && (widget.user.profileImageBase64 == null || widget.user.profileImageBase64!.isEmpty)
                      ? Icon(Icons.add_a_photo, color: Colors.teal.shade700)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(_pickingImage ? 'Loading...' : 'Tap to change photo', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (!isGuardian) ...[
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
                  items: _bloodGroups.map((bg) => DropdownMenuItem(value: bg, child: Text(bg))).toList(),
                  onChanged: (val) => setState(() => _selectedBloodGroup = val),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
