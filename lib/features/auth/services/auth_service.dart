import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:memory_assist/features/auth/services/role_service.dart';

final authServiceProvider = Provider((ref) => AuthService(ref.read(roleServiceProvider)));

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleService _roleService;

  AuthService(this._roleService);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String role,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? bloodGroup,
    String? profileImageBase64,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Generate Link Code for Guardians
      String? linkCode;
      if (role == 'guardian') {
         // Simple 6-char code
         const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
         final rng = Random();
         linkCode = List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
      }

      // Create user document in Firestore
      if (credential.user != null) {
        final userModel = {
          'uid': credential.user!.uid,
          'email': email,
          'role': role,
          'name': name,
          'age': age,
          'height': height,
          'weight': weight,
          'blood_group': bloodGroup,
          'profile_image_base64': profileImageBase64,
          'link_code': linkCode,
          'linked_uids': [],
          'created_at': FieldValue.serverTimestamp(),
        };
        
        await _firestore.collection('users').doc(credential.user!.uid).set(userModel);
      }
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _roleService.clearLocalRole();
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<String?> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
  Future<void> linkAccounts(String currentUid, String linkCode) async {
    try {
      // 1. Find the user with the given link code (Guardian)
      final querySnapshot = await _firestore
          .collection('users')
          .where('link_code', isEqualTo: linkCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid link code. No user found.');
      }

      final guardianDoc = querySnapshot.docs.first;
      final guardianUid = guardianDoc.id;

      if (guardianUid == currentUid) {
         throw Exception('You cannot link to yourself.');
      }
      
      // 2. Add Guardian UID to Patient's linked_uids
      await _firestore.collection('users').doc(currentUid).update({
        'linked_uids': FieldValue.arrayUnion([guardianUid])
      });

      // 3. Add Patient UID to Guardian's linked_uids
      await _firestore.collection('users').doc(guardianUid).update({
        'linked_uids': FieldValue.arrayUnion([currentUid])
      });

    } catch (e) {
      rethrow;
    }
  }
}
