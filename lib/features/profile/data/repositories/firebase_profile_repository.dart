import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseProfileRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('A signed-in user is required.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> get _profileDocument =>
      _firestore.collection('users').doc(_user.uid);

  @override
  Stream<UserProfile> watchProfile() {
    final user = _user;
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      return UserProfile(
        displayName: data['displayName'] as String? ?? user.displayName ?? '',
        email: user.email ?? '',
        address: data['address'] as String? ?? '',
        photoUrl: data['photoUrl'] as String? ?? user.photoURL ?? '',
      );
    });
  }

  @override
  Future<void> updatePersonalData({
    required String displayName,
    required String address,
  }) async {
    final user = _user;
    await user.updateDisplayName(displayName.trim());
    await _profileDocument.set({
      'displayName': displayName.trim(),
      'address': address.trim(),
      'photoUrl': user.photoURL ?? '',
      'pendingEmail': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<String> updateProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _user;
    final extension = fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final reference = _storage.ref(
      'users/${user.uid}/profile/avatar.$extension',
    );
    await reference.putData(
      bytes,
      SettableMetadata(contentType: 'image/$extension'),
    );
    final url = await reference.getDownloadURL();
    await user.updatePhotoURL(url);
    final existing = (await _profileDocument.get()).data();
    await _profileDocument.set({
      'displayName': user.displayName ?? '',
      'address': existing?['address'] as String? ?? '',
      'photoUrl': url,
      'pendingEmail': existing?['pendingEmail'] as String? ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _user;
    await _reauthenticate(user, currentPassword);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
    final existing = (await _profileDocument.get()).data();
    await _profileDocument.set({
      'displayName': user.displayName ?? '',
      'address': existing?['address'] as String? ?? '',
      'photoUrl': user.photoURL ?? '',
      'pendingEmail': newEmail.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _user;
    await _reauthenticate(user, currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> _reauthenticate(User user, String password) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw StateError('This account does not have an email address.');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }
}
