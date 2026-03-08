import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_assist/features/auth/services/auth_service.dart';
import 'package:memory_assist/features/auth/screens/signup_screen.dart';
import 'package:memory_assist/features/guardian/screens/guardian_home_screen.dart';
import 'package:memory_assist/features/patient/screens/patient_home_screen.dart';
import 'package:memory_assist/features/auth/services/role_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role; // 'guardian' or 'patient'
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final roleService = ref.read(roleServiceProvider);
      
      // 1. Sign In
      final credential = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (credential?.user == null) throw Exception('User not found');

      // 2. Fetch Actual Role from Firestore
      final actualRole = await authService.getUserRole(credential!.user!.uid);
      
      if (!mounted) return;

      String finalRole = widget.role;

      if (actualRole != null && actualRole != widget.role) {
        // Role mismatch: selected 'guardian' but account is 'patient' (or vice versa)
        final shouldSwitch = await _showRoleConflictDialog(context, actualRole, widget.role);
        
        if (shouldSwitch == null) {
          // User cancelled
          await authService.signOut();
          return;
        }

        if (shouldSwitch) {
          // Update Firestore role
          await authService.updateUser(credential.user!.uid, {'role': widget.role});
          finalRole = widget.role;
        } else {
          // Use session role
          finalRole = actualRole; 
        }
      }

      // 3. Save role locally for this device
      await roleService.setLocalRole(finalRole);

      if (!mounted) return;

      if (finalRole == 'guardian') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const GuardianHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showRoleConflictDialog(BuildContext context, String currentRole, String selectedRole) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Role Mismatch'),
        content: Text(
          'Your account is currently set as a $currentRole. \n\n'
          'Would you like to switch this account to $selectedRole permanently, or continue as $currentRole on this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Use $currentRole'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Switch to $selectedRole'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian = widget.role == 'guardian';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isGuardian ? 'Guardian Login' : 'Patient Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isGuardian ? Colors.teal : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpScreen(role: widget.role)),
                  );
                },
                child: const Text('Create Account instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
