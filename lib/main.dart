import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memory_assist/core/theme/app_theme.dart';
import 'package:memory_assist/features/auth/screens/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Uncomment after adding google-services.json
  
  runApp(const ProviderScope(child: MemoryAssistApp()));
}

class MemoryAssistApp extends StatelessWidget {
  const MemoryAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Assist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.guardianTheme, // Default theme
      home: const RoleSelectionScreen(),
    );
  }
}
