import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../libraries/core/localization/language_controller.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthModeToggled>(_onModeToggled);
    on<AuthPasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<AuthConfirmationVisibilityToggled>(_onConfirmationVisibilityToggled);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(
      _repository.hasSignedInUser
          ? AuthAuthenticated(
              isRegisterMode: state.isRegisterMode,
              obscurePassword: state.obscurePassword,
              obscureConfirmation: state.obscureConfirmation,
            )
          : AuthUnauthenticated(
              isRegisterMode: state.isRegisterMode,
              obscurePassword: state.obscurePassword,
              obscureConfirmation: state.obscureConfirmation,
            ),
    );
  }

  void _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) {
    emit(
      AuthFormUpdated(
        isRegisterMode: !state.isRegisterMode,
        obscurePassword: state.obscurePassword,
        obscureConfirmation: state.obscureConfirmation,
      ),
    );
  }

  void _onPasswordVisibilityToggled(
    AuthPasswordVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(
      AuthFormUpdated(
        isRegisterMode: state.isRegisterMode,
        obscurePassword: !state.obscurePassword,
        obscureConfirmation: state.obscureConfirmation,
      ),
    );
  }

  void _onConfirmationVisibilityToggled(
    AuthConfirmationVisibilityToggled event,
    Emitter<AuthState> emit,
  ) {
    emit(
      AuthFormUpdated(
        isRegisterMode: state.isRegisterMode,
        obscurePassword: state.obscurePassword,
        obscureConfirmation: !state.obscureConfirmation,
      ),
    );
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthentication(
      emit,
      () => _repository.signIn(email: event.email, password: event.password),
    );
  }

  Future<void> _onRegisterSubmitted(
    AuthRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    await _runAuthentication(
      emit,
      () => _repository.register(email: event.email, password: event.password),
    );
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_loadingState());
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(
        AuthActionSuccess(
          LanguageController.instance.translate(LanguageKeys.passwordResetSent),
          isRegisterMode: state.isRegisterMode,
          obscurePassword: state.obscurePassword,
          obscureConfirmation: state.obscureConfirmation,
        ),
      );
    } on AuthenticationFailure catch (error) {
      emit(_failureState(error.message));
    } catch (_) {
      emit(
        _failureState(
          LanguageController.instance.translate(
            LanguageKeys.passwordResetFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_loadingState());
    try {
      await _repository.signOut();
      emit(
        AuthUnauthenticated(
          isRegisterMode: state.isRegisterMode,
          obscurePassword: state.obscurePassword,
          obscureConfirmation: state.obscureConfirmation,
        ),
      );
    } on AuthenticationFailure catch (error) {
      emit(_failureState(error.message));
    }
  }

  Future<void> _runAuthentication(
    Emitter<AuthState> emit,
    Future<void> Function() action,
  ) async {
    emit(_loadingState());
    try {
      await action();
      emit(
        AuthAuthenticated(
          isRegisterMode: state.isRegisterMode,
          obscurePassword: state.obscurePassword,
          obscureConfirmation: state.obscureConfirmation,
        ),
      );
    } on AuthenticationFailure catch (error) {
      emit(_failureState(error.message));
    } catch (_) {
      emit(
        _failureState(
          LanguageController.instance.translate(
            LanguageKeys.authenticationFailed,
          ),
        ),
      );
    }
  }

  AuthLoading _loadingState() => AuthLoading(
    isRegisterMode: state.isRegisterMode,
    obscurePassword: state.obscurePassword,
    obscureConfirmation: state.obscureConfirmation,
  );

  AuthFailure _failureState(String message) => AuthFailure(
    message,
    isRegisterMode: state.isRegisterMode,
    obscurePassword: state.obscurePassword,
    obscureConfirmation: state.obscureConfirmation,
  );
}
