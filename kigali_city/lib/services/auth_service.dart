import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.idTokenChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

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
      await credential.user?.delete();
      rethrow;
    }

    await credential.user?.sendEmailVerification();

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateNotificationPreference(String uid, bool enabled) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationsEnabled': enabled,
    });
  }

  /// Pass [isCurrentlyLiked] = true to unlike, false to like.
  Future<void> toggleLike(
    String uid,
    String listingId, {
    required bool isCurrentlyLiked,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'likedListings': isCurrentlyLiked
          ? FieldValue.arrayRemove([listingId])
          : FieldValue.arrayUnion([listingId]),
    });
  }

  Stream<List<String>> getLikedListingIds(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['likedListings'] ?? []);
    });
  }
}
