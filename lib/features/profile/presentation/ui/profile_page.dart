import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/theme/app_colors.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  final ProfileRepository repository;

  const ProfilePage({super.key, required this.repository});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(context.tr(LanguageKeys.profileDetails)),
      ),
      body: StreamBuilder<UserProfile>(
        stream: widget.repository.watchProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(context.tr(LanguageKeys.profileUpdateFailed)),
            );
          }
          final profile = snapshot.data!;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  _ProfileHeader(
                    profile: profile,
                    onChangePhoto: _busy ? null : () => _changePhoto(profile),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(context.tr(LanguageKeys.personalInformation)),
                  const SizedBox(height: 10),
                  _ProfileMenuCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(context.tr(LanguageKeys.displayName)),
                        subtitle: Text(
                          profile.displayName.isEmpty
                              ? '—'
                              : profile.displayName,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () => _editPersonalData(profile),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(context.tr(LanguageKeys.address)),
                        subtitle: Text(
                          profile.address.isEmpty ? '—' : profile.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () => _editPersonalData(profile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(context.tr(LanguageKeys.security)),
                  const SizedBox(height: 10),
                  _ProfileMenuCard(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.alternate_email_rounded),
                        title: Text(context.tr(LanguageKeys.changeEmail)),
                        subtitle: Text(profile.email),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : () => _changeEmail(profile.email),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: Text(context.tr(LanguageKeys.changePassword)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _busy ? null : _changePassword,
                      ),
                    ],
                  ),
                ],
              ),
              if (_busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _changePhoto(UserProfile profile) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    await _run(
      () async {
        await widget.repository.updateProfilePhoto(
          bytes: await image.readAsBytes(),
          fileName: image.name,
        );
      },
      successKey: LanguageKeys.photoUpdated,
      failureKey: LanguageKeys.photoUpdateFailed,
    );
  }

  Future<void> _editPersonalData(UserProfile profile) async {
    final result = await showModalBottomSheet<_PersonalData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PersonalDataSheet(profile: profile),
    );
    if (result == null || !mounted) return;
    await _run(
      () => widget.repository.updatePersonalData(
        displayName: result.displayName,
        address: result.address,
      ),
      successKey: LanguageKeys.profileUpdated,
      failureKey: LanguageKeys.profileUpdateFailed,
    );
  }

  Future<void> _changeEmail(String email) async {
    final result = await showDialog<_EmailChange>(
      context: context,
      builder: (_) => _ChangeEmailDialog(currentEmail: email),
    );
    if (result == null || !mounted) return;
    await _run(
      () => widget.repository.updateEmail(
        currentPassword: result.currentPassword,
        newEmail: result.newEmail,
      ),
      successKey: LanguageKeys.emailVerificationSent,
      failureKey: LanguageKeys.profileUpdateFailed,
    );
  }

  Future<void> _changePassword() async {
    final result = await showDialog<_PasswordChange>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == null || !mounted) return;
    await _run(
      () => widget.repository.updatePassword(
        currentPassword: result.currentPassword,
        newPassword: result.newPassword,
      ),
      successKey: LanguageKeys.passwordUpdated,
      failureKey: LanguageKeys.profileUpdateFailed,
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String successKey,
    required String failureKey,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _message(successKey);
    } catch (_) {
      if (mounted) _message(failureKey);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(key)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onChangePhoto;

  const _ProfileHeader({required this.profile, required this.onChangePhoto});

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.trim().isEmpty
        ? 'U'
        : profile.displayName.trim()[0].toUpperCase();
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primaryContainer,
              backgroundImage: profile.photoUrl.isEmpty
                  ? null
                  : NetworkImage(profile.photoUrl),
              child: profile.photoUrl.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: IconButton.filled(
                onPressed: onChangePhoto,
                tooltip: context.tr(LanguageKeys.changePhoto),
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.displayName.isEmpty ? profile.email : profile.displayName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(profile.email, style: const TextStyle(color: Color(0xFF718078))),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
  );
}

class _ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileMenuCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(children: children),
  );
}

class _PersonalDataSheet extends StatefulWidget {
  final UserProfile profile;

  const _PersonalDataSheet({required this.profile});

  @override
  State<_PersonalDataSheet> createState() => _PersonalDataSheetState();
}

class _PersonalDataSheetState extends State<_PersonalDataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _address = TextEditingController(text: widget.profile.address);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(LanguageKeys.personalInformation),
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: context.tr(LanguageKeys.displayName),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? context.tr(LanguageKeys.displayNameRequired)
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.tr(LanguageKeys.address),
              hintText: context.tr(LanguageKeys.addressHint),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(
                context,
                _PersonalData(_name.text.trim(), _address.text.trim()),
              );
            },
            child: Text(context.tr(LanguageKeys.saveChanges)),
          ),
        ],
      ),
    ),
  );
}

class _ChangeEmailDialog extends StatefulWidget {
  final String currentEmail;

  const _ChangeEmailDialog({required this.currentEmail});

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(LanguageKeys.changeEmail)),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: context.tr(LanguageKeys.newEmail),
            ),
            validator: (value) => value == null || !value.contains('@')
                ? context.tr(LanguageKeys.invalidEmail)
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr(LanguageKeys.currentPassword),
            ),
            validator: (value) => value == null || value.isEmpty
                ? context.tr(LanguageKeys.passwordRequired)
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr(LanguageKeys.cancel)),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(context.tr(LanguageKeys.send)),
      ),
    ],
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _EmailChange(_password.text, _email.text.trim()));
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(LanguageKeys.changePassword)),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _passwordField(_current, LanguageKeys.currentPassword),
          const SizedBox(height: 12),
          _passwordField(_next, LanguageKeys.newPassword, minimum: true),
          const SizedBox(height: 12),
          _passwordField(
            _confirm,
            LanguageKeys.confirmNewPassword,
            confirm: true,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr(LanguageKeys.cancel)),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(context.tr(LanguageKeys.saveChanges)),
      ),
    ],
  );

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    bool minimum = false,
    bool confirm = false,
  }) => TextFormField(
    controller: controller,
    obscureText: true,
    decoration: InputDecoration(labelText: context.tr(label)),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return context.tr(LanguageKeys.passwordRequired);
      }
      if (minimum && value.length < 6) {
        return context.tr(LanguageKeys.minimumPassword);
      }
      if (confirm && value != _next.text) {
        return context.tr(LanguageKeys.passwordsDoNotMatch);
      }
      return null;
    },
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _PasswordChange(_current.text, _next.text));
  }
}

class _PersonalData {
  final String displayName;
  final String address;

  const _PersonalData(this.displayName, this.address);
}

class _EmailChange {
  final String currentPassword;
  final String newEmail;

  const _EmailChange(this.currentPassword, this.newEmail);
}

class _PasswordChange {
  final String currentPassword;
  final String newPassword;

  const _PasswordChange(this.currentPassword, this.newPassword);
}
