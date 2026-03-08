import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectedAccountsScreen extends ConsumerStatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  ConsumerState<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends ConsumerState<ConnectedAccountsScreen> {
  final TextEditingController _linkCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _linkCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkAccount(String currentUid) async {
    final code = _linkCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).linkAccounts(currentUid, code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account linked successfully!')),
        );
        _linkCodeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Connected Device')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: authService.getUserStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final role = userData['role'] as String? ?? 'patient';
          final linkCode = userData['link_code'] as String?; // Only for guardians
          final linkedUids = List<String>.from(userData['linked_uids'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role == 'guardian') 
                  _buildGuardianSection(linkCode)
                else 
                  _buildPatientSection(currentUser.uid),

                const SizedBox(height: 24),
                Text(
                  role == 'guardian' ? 'Connected Patients:' : 'Connected Guardians:', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                
                const SizedBox(height: 8),
                if (linkedUids.isEmpty)
                  const Text('No connected accounts yet.', style: TextStyle(color: Colors.grey))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: linkedUids.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(linkedUids[index]).get(),
                        builder: (context, snap) {
                           if (!snap.hasData) return const ListTile(title: Text('Loading...'));
                           final data = snap.data!.data() as Map<String, dynamic>?;
                           if (data == null) return const SizedBox.shrink();
                           
                           // Basic initial info
                           final name = data['name'] ?? 'Unknown';
                           final email = data['email'] ?? '';
                           
                           return Card(
                             margin: const EdgeInsets.only(bottom: 8),
                             child: ListTile(
                               leading: const CircleAvatar(child: Icon(Icons.person)),
                               title: Text(name),
                               subtitle: Text(email),
                             ),
                           );
                        }
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuardianSection(String? linkCode) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Your Link Code',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  linkCode ?? 'N/A',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: linkCode == null ? null : () {
                    Clipboard.setData(ClipboardData(text: linkCode));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied to clipboard')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy Code',
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with the patient to link accounts.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSection(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect to Guardian',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _linkCodeController,
          decoration: const InputDecoration(
            labelText: 'Enter Guardian Link Code',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
            helperText: 'Ask your guardian for their 6-character code',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _linkAccount(uid),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Connect'),
          ),
        ),
      ],
    );
  }
}
