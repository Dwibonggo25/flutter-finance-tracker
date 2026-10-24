import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../libraries/core/firebase/firebase_config.dart';
import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/theme/app_colors.dart';
import '../../../../libraries/core/theme/theme_controller.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => Modular.get<AuthBloc>()..add(const AuthStarted()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                Modular.to.navigate('/home/');
              } else if (state is AuthFailure) {
                _showMessage(context, state.message, isError: true);
              } else if (state is AuthActionSuccess) {
                _showMessage(context, state.message);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),
                        const SizedBox(height: 28),
                        const _BalancePreview(),
                        const SizedBox(height: 24),
                        if (!FirebaseConfig.isConfigured) ...[
                          const _FirebaseSetupNotice(),
                          const SizedBox(height: 16),
                        ],
                        _buildForm(context, isLoading),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.22)
                : const Color(0x0D15261F),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  _isRegisterMode
                      ? LanguageKeys.createAccount
                      : LanguageKeys.welcome,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  _isRegisterMode
                      ? LanguageKeys.registerSubtitle
                      : LanguageKeys.loginSubtitle,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: _inputDecoration(
                  label: context.tr(LanguageKeys.email),
                  hint: context.tr(LanguageKeys.emailHint),
                  icon: Icons.mail_outline_rounded,
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                textInputAction: _isRegisterMode
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: _isRegisterMode
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration:
                    _inputDecoration(
                      label: context.tr(LanguageKeys.password),
                      hint: context.tr(LanguageKeys.passwordHint),
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        tooltip: context.tr(
                          _obscurePassword
                              ? LanguageKeys.showPassword
                              : LanguageKeys.hidePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                validator: _validatePassword,
                onFieldSubmitted: _isRegisterMode
                    ? null
                    : (_) => _submit(context),
              ),
              if (_isRegisterMode) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: _obscureConfirmation,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration:
                      _inputDecoration(
                        label: context.tr(LanguageKeys.confirmPassword),
                        hint: context.tr(LanguageKeys.repeatPassword),
                        icon: Icons.verified_user_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          tooltip: context.tr(
                            _obscureConfirmation
                                ? LanguageKeys.showPassword
                                : LanguageKeys.hidePassword,
                          ),
                          icon: Icon(
                            _obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return LanguageController.instance.translate(
                        LanguageKeys.passwordsDoNotMatch,
                      );
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(context),
                ),
              ],
              if (!_isRegisterMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => _showResetPasswordDialog(context),
                    child: Text(context.tr(LanguageKeys.forgotPassword)),
                  ),
                )
              else
                const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: isLoading ? null : () => _submit(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFF96B8CA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr(
                              _isRegisterMode
                                  ? LanguageKeys.register
                                  : LanguageKeys.login,
                            ),
                            key: const ValueKey('label'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.tr(
                      _isRegisterMode
                          ? LanguageKeys.alreadyHaveAccount
                          : LanguageKeys.noAccount,
                    ),
                    style: const TextStyle(color: Color(0xFF66736C)),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : _toggleMode,
                    child: Text(
                      context.tr(
                        _isRegisterMode
                            ? LanguageKeys.login
                            : LanguageKeys.register,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF7F9F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE4DD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDCE4DD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return LanguageController.instance.translate(LanguageKeys.emailRequired);
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return LanguageController.instance.translate(LanguageKeys.invalidEmail);
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return LanguageController.instance.translate(
        LanguageKeys.passwordRequired,
      );
    }
    if (value.length < 6) {
      return LanguageController.instance.translate(
        LanguageKeys.minimumPassword,
      );
    }
    return null;
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final bloc = BlocProvider.of<AuthBloc>(context);
    if (_isRegisterMode) {
      bloc.add(
        AuthRegisterSubmitted(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    } else {
      bloc.add(
        AuthLoginSubmitted(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _confirmPasswordController.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<void> _showResetPasswordDialog(BuildContext context) async {
    final bloc = BlocProvider.of<AuthBloc>(context);
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr(LanguageKeys.resetPassword)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: InputDecoration(
            labelText: dialogContext.tr(LanguageKeys.email),
            hintText: dialogContext.tr(LanguageKeys.emailHint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.tr(LanguageKeys.cancel)),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (_validateEmail(value) == null) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: Text(dialogContext.tr(LanguageKeys.send)),
          ),
        ],
      ),
    );

    controller.dispose();
    if (email != null) bloc.add(AuthPasswordResetRequested(email));
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFF9B2C2C)
              : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FINANCE PROJECT',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(LanguageKeys.brandTagline),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: context.tr(LanguageKeys.appearance),
          icon: const Icon(Icons.settings_outlined),
          onSelected: (value) {
            if (value == 'id' || value == 'en') {
              LanguageController.instance.changeLanguage(value);
            } else if (value == 'theme_light') {
              ThemeController.instance.changeTheme(ThemeMode.light);
            } else if (value == 'theme_dark') {
              ThemeController.instance.changeTheme(ThemeMode.dark);
            }
          },
          itemBuilder: (menuContext) => [
            PopupMenuItem(
              value: 'id',
              child: Text(menuContext.tr(LanguageKeys.indonesian)),
            ),
            PopupMenuItem(
              value: 'en',
              child: Text(menuContext.tr(LanguageKeys.english)),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'theme_light',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.light_mode_outlined),
                title: Text(menuContext.tr(LanguageKeys.lightMode)),
                trailing: ThemeController.instance.value == ThemeMode.light
                    ? const Icon(Icons.check_rounded)
                    : null,
              ),
            ),
            PopupMenuItem(
              value: 'theme_dark',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(menuContext.tr(LanguageKeys.darkMode)),
                trailing: ThemeController.instance.value == ThemeMode.dark
                    ? const Icon(Icons.check_rounded)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(LanguageKeys.takeControl),
                  style: const TextStyle(
                    color: Color(0xFFC9EDFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(LanguageKeys.brandMessage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.trending_up_rounded,
            size: 58,
            color: Color(0xFF91DEB9),
          ),
        ],
      ),
    );
  }
}

class _FirebaseSetupNotice extends StatelessWidget {
  const _FirebaseSetupNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1D68B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF855F00)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(LanguageKeys.firebaseSetupNotice),
              style: const TextStyle(color: Color(0xFF6B4D00), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
