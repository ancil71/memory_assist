import 'package:flutter/material.dart';
import 'package:memory_assist/features/guardian/screens/guardian_home_screen.dart';
import 'package:memory_assist/features/patient/screens/patient_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'guardian' or 'patient'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    // TODO: Implement Firebase Auth Logic
    // For now, mock navigation based on role
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    
    if (!mounted) return;

    if (widget.role == 'guardian') {
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
  }

  @override
  Widget build(BuildContext context) {
    final isGuardian = widget.role == 'guardian';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuardian ? 'Guardian Login' : 'Patient Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
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
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Implement Registration Navigation
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
