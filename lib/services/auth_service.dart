import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  //login : email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //register : email/password
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
          'email':           email,
          'solde':           0.0,
          'soldeMinimum':    100.0,
          'limiteTransaction': -20.0,
          'isBlocked':       false,
          'blockedReason':   null,
          'cardNumber':      '****',
          'fcmToken':        null,
          'createdAt':       FieldValue.serverTimestamp(),

        });
  }

  //logout
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
