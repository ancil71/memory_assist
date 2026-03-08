import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';
import 'package:memory_assist/features/auth/screens/role_selection_screen.dart';
import 'package:memory_assist/features/settings/screens/connected_accounts_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Connected Device'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
             onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConnectedAccountsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            subtitle: const Text('Version 1.0.0'),
          ),
          const Divider(),
           ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
