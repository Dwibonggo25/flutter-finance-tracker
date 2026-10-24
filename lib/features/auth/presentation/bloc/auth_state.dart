import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  final bool isRegisterMode;
  final bool obscurePassword;
  final bool obscureConfirmation;

  const AuthState({
    this.isRegisterMode = false,
    this.obscurePassword = true,
    this.obscureConfirmation = true,
  });

  @override
  List<Object?> get props => [
    isRegisterMode,
    obscurePassword,
    obscureConfirmation,
  ];
}

final class AuthInitial extends AuthState {
  const AuthInitial({
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });
}

final class AuthFormUpdated extends AuthState {
  const AuthFormUpdated({
    required super.isRegisterMode,
    required super.obscurePassword,
    required super.obscureConfirmation,
  });
}

final class AuthLoading extends AuthState {
  const AuthLoading({
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });
}

final class AuthActionSuccess extends AuthState {
  final String message;

  const AuthActionSuccess(
    this.message, {
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

final class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(
    this.message, {
    super.isRegisterMode,
    super.obscurePassword,
    super.obscureConfirmation,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
