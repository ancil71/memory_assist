import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

final linkServiceProvider = Provider((ref) => LinkService());

class LinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a random 6-digit code for the Guardian
  String _generateCode() {
    var rng = Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  Future<void> generateLinkCode(String guardianUid) async {
    final code = _generateCode();
    await _firestore.collection('users').doc(guardianUid).update({
      'link_code': code,
    });
  }

  // Patient uses this to link to a Guardian
  Future<bool> linkPatientToGuardian(String patientUid, String code) async {
    try {
      // Find Guardian with this code
      final querySnapshot = await _firestore
          .collection('users')
          .where('link_code', isEqualTo: code)
          .where('role', isEqualTo: 'guardian')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false; // Code not found
      }

      final guardianDoc = querySnapshot.docs.first;
      final guardianUid = guardianDoc.id;

      // Perform Linking in a Transaction
      await _firestore.runTransaction((transaction) async {
        final guardianRef = _firestore.collection('users').doc(guardianUid);
        final patientRef = _firestore.collection('users').doc(patientUid);

        transaction.update(guardianRef, {
          'linked_uids': FieldValue.arrayUnion([patientUid]),
        });

        transaction.update(patientRef, {
          'linked_uids': FieldValue.arrayUnion([guardianUid]),
        });
      });

      return true;
    } catch (e) {
      print('Error linking users: $e');
      return false;
    }
  }
}
