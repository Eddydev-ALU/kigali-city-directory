import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Using idTokenChanges so the stream also re-emits when emailVerified
  /// changes (after the user clicks the verification link and the token
  /// is refreshed with getIdToken(true)).
  Stream<User?> get authStateChanges => _auth.idTokenChanges();

  User? get currentUser => _auth.currentUser;

  /// Sign up with email and password, then create Firestore user profile
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // Create user profile in Firestore
    final userModel = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    try {
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());
    } catch (e) {
      // Firestore write failed – delete the Auth account so the user
      // is not left in a broken half-registered state, then rethrow.
      await credential.user?.delete();
      rethrow;
    }

    // Send email verification
    await credential.user?.sendEmailVerification();

    return credential;
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Resend email verification
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reload user to refresh email verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Check if current user has verified their email
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch the UserModel from Firestore for the current user
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update notification preference in Firestore
  Future<void> updateNotificationPreference(String uid, bool enabled) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationsEnabled': enabled,
    });
  }
}
