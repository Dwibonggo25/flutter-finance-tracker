import 'dart:typed_data';

import 'package:finance_project/features/profile/domain/entities/user_profile.dart';
import 'package:finance_project/features/profile/domain/repositories/profile_repository.dart';
import 'package:finance_project/features/profile/presentation/ui/profile_page.dart';
import 'package:finance_project/libraries/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows profile identity and account security actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePage(repository: _FakeProfileRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dwi Bonggo'), findsWidgets);
    expect(find.text('dwi@example.com'), findsWidgets);
    expect(find.text('Change email'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
  });
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Stream<UserProfile> watchProfile() => Stream.value(
    const UserProfile(
      displayName: 'Dwi Bonggo',
      email: 'dwi@example.com',
      address: 'Indonesia',
    ),
  );

  @override
  Future<void> updateEmail({
    required String currentPassword,
    required String newEmail,
  }) => throw UnimplementedError();

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> updatePersonalData({
    required String displayName,
    required String address,
  }) => throw UnimplementedError();

  @override
  Future<String> updateProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) => throw UnimplementedError();
}
