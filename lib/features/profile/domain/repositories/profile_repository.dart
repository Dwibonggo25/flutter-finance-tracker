import 'dart:typed_data';

import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Stream<UserProfile> watchProfile();

  Future<void> updatePersonalData({
    required String displayName,
    required String address,
  });

  Future<String> updateProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  });

  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
}
