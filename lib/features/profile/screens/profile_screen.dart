import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_assist/core/models/user_model.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';
import 'package:memory_assist/features/auth/screens/role_selection_screen.dart';
import 'package:memory_assist/features/profile/screens/edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserModel? _user;
  UserModel? _guardian;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromMap(doc.data()!);
        UserModel? foundGuardian;
        
        // Fetch guardian if patient
        if (userModel.role == 'patient' && userModel.linkedUids.isNotEmpty) {
           for (final linkedId in userModel.linkedUids) {
             final gDoc = await FirebaseFirestore.instance.collection('users').doc(linkedId).get();
             if (gDoc.exists) {
               final potentialGuardian = UserModel.fromMap(gDoc.data()!);
               if (potentialGuardian.role == 'guardian') {
                 foundGuardian = potentialGuardian;
                 break;
               }
             }
           }
        }

        if (mounted) {
          setState(() {
            _user = userModel;
            _guardian = foundGuardian;
            _isLoading = false;
          });
        }
      }
    }
  }

  Uint8List _decodeImage(String base64) {
    try {
      return base64Decode(base64);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_user == null) return const Scaffold(body: Center(child: Text('User not found')));

    final isGuardian = _user!.role == 'guardian';
    // Always show the current logged-in user's profile (patient sees their own, guardian sees their own).
    final appBarTitle = isGuardian ? 'Profile' : 'My Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
                );
                if (updated == true) _fetchProfile();
              },
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  _user!.profileImageBase64 != null && _user!.profileImageBase64!.isNotEmpty
                      ? (_decodeImage(_user!.profileImageBase64!).isNotEmpty
                          ? CircleAvatar(
                              radius: 50,
                              backgroundImage: MemoryImage(_decodeImage(_user!.profileImageBase64!)),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.teal.shade100,
                              child: const Icon(Icons.person, size: 50, color: Colors.teal),
                            ))
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.person, size: 50, color: Colors.teal),
                        ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tap photo to add or change',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 32),
          
          // My Details Section
          const Text("My Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileItem(label: 'Name', value: _user!.name ?? 'N/A'),
                  const Divider(),
                  _ProfileItem(label: 'Email', value: _user!.email),
                  const Divider(),
                  _ProfileItem(label: 'Role', value: _user!.role.toUpperCase()),
                  if (_user!.phone != null && _user!.phone!.isNotEmpty) ...[
                    const Divider(),
                    _ProfileItem(label: 'Phone', value: _user!.phone!),
                  ],
                  if (_user!.address != null && _user!.address!.isNotEmpty) ...[
                    const Divider(),
                    _ProfileItem(label: 'Address', value: _user!.address!),
                  ],
                ],
              ),
            ),
          ),

          if (!isGuardian) ...[
             const SizedBox(height: 24),
             const Text("Medical Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
             const SizedBox(height: 8),
             Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ProfileItem(label: 'Age', value: _user!.age?.toString() ?? 'N/A'),
                      const Divider(),
                      _ProfileItem(label: 'Blood Group', value: _user!.bloodGroup ?? 'N/A'),
                      const Divider(),
                      _ProfileItem(label: 'Height', value: '${_user!.height ?? 0} cm'),
                      const Divider(),
                      _ProfileItem(label: 'Weight', value: '${_user!.weight ?? 0} kg'),
                    ],
                  ),
                ),
             ),
          ],
          
          if (!isGuardian && _guardian != null) ...[
            const SizedBox(height: 24),
             Row(
               children: [
                 const Icon(Icons.shield, color: Colors.indigo),
                 const SizedBox(width: 8),
                 Text("Guardian Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo.shade700)),
               ],
             ),
            const SizedBox(height: 8),
            Card(
              color: Colors.indigo.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ProfileItem(label: 'Name', value: _guardian!.name ?? 'N/A'),
                    const Divider(),
                    _ProfileItem(label: 'Phone', value: _guardian!.phone ?? 'N/A'),
                    const Divider(),
                    _ProfileItem(label: 'Email', value: _guardian!.email),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
          // Add Edit Button Placeholder
          OutlinedButton.icon(
             onPressed: () async {
               final bool? updated = await Navigator.push(
                 context,
                 MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user!)),
               );
               if (updated == true) {
                 _fetchProfile(); // Refresh data
               }
             },
             icon: const Icon(Icons.edit),
             label: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
