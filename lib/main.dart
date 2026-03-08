import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:memory_assist/core/theme/app_theme.dart';
import 'package:memory_assist/features/auth/screens/role_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_assist/features/guardian/screens/guardian_home_screen.dart';
import 'package:memory_assist/features/patient/screens/patient_home_screen.dart';
import 'package:memory_assist/features/auth/services/role_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB2j3N0BpfK_EbD2hA655EfBDJ02Vgg9eI",
          authDomain: "memory-assist-c1dfd.firebaseapp.com",
          projectId: "memory-assist-c1dfd",
          storageBucket: "memory-assist-c1dfd.firebasestorage.app",
          messagingSenderId: "119074168485",
          appId: "1:119074168485:web:0c57423710a7d7e482b74c",
          measurementId: "G-PZ0Z5WWTX1",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    debugPrint('Firebase init error: $e');
    debugPrint('$st');
    rethrow;
  }

  // Show a readable error on widget build failures instead of red screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              details.exceptionAsString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  };

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          final uid = snapshot.data!.uid;
          
          return FutureBuilder<String?>(
            // 1. First check local role override
            future: ref.read(roleServiceProvider).getLocalRole(),
            builder: (context, localRoleSnapshot) {
              if (localRoleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final localRole = localRoleSnapshot.data;

              return FutureBuilder<DocumentSnapshot>(
                // 2. Fetch Firestore data (needed for both cases, e.g. for SOS listening in home)
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const RoleSelectionScreen(); 
                  }

                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  final firestoreRole = data?['role'] as String?;

                  // Determine effective role: Local override takes precedence
                  final effectiveRole = localRole ?? firestoreRole;

                  // If no local role, save the Firestore role as the default local role
                  if (localRole == null && firestoreRole != null) {
                    ref.read(roleServiceProvider).setLocalRole(firestoreRole);
                  }

                  if (effectiveRole == 'guardian') {
                    return const GuardianHomeScreen();
                  } else if (effectiveRole == 'patient') {
                    return const PatientHomeScreen();
                  } else {
                    return const RoleSelectionScreen();
                  }
                },
              );
            },
          );
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
