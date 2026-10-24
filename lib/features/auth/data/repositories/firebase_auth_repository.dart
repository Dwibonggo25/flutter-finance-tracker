import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw AuthenticationFailure(_tr(LanguageKeys.firebaseNotConfigured));
    }
    return FirebaseAuth.instance;
  }

  @override
  bool get hasSignedInUser {
    if (Firebase.apps.isEmpty) return false;
    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthenticationFailure(_messageFor(error));
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthenticationFailure(_messageFor(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthenticationFailure(_messageFor(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthenticationFailure(_messageFor(error));
    }
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => _tr(LanguageKeys.invalidEmail),
      'user-disabled' => _tr(LanguageKeys.accountDisabled),
      'user-not-found' ||
      'invalid-credential' => _tr(LanguageKeys.invalidCredentials),
      'wrong-password' => _tr(LanguageKeys.invalidCredentials),
      'email-already-in-use' => _tr(LanguageKeys.emailAlreadyUsed),
      'weak-password' => _tr(LanguageKeys.weakPassword),
      'too-many-requests' => _tr(LanguageKeys.tooManyRequests),
      'network-request-failed' => _tr(LanguageKeys.networkFailure),
      'operation-not-allowed' => _tr(LanguageKeys.authProviderDisabled),
      _ => error.message ?? _tr(LanguageKeys.authenticationFailed),
    };
  }

  String _tr(String key) => LanguageController.instance.translate(key);
}
