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
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthRegisterSubmitted>(_onRegisterSubmitted);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    emit(
      _repository.hasSignedInUser
          ? const AuthAuthenticated()
          : const AuthUnauthenticated(),
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
    emit(const AuthLoading());
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(
        AuthActionSuccess(
          LanguageController.instance.translate(LanguageKeys.passwordResetSent),
        ),
      );
    } on AuthenticationFailure catch (error) {
      emit(AuthFailure(error.message));
    } catch (_) {
      emit(
        AuthFailure(
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
    emit(const AuthLoading());
    try {
      await _repository.signOut();
      emit(const AuthUnauthenticated());
    } on AuthenticationFailure catch (error) {
      emit(AuthFailure(error.message));
    }
  }

  Future<void> _runAuthentication(
    Emitter<AuthState> emit,
    Future<void> Function() action,
  ) async {
    emit(const AuthLoading());
    try {
      await action();
      emit(const AuthAuthenticated());
    } on AuthenticationFailure catch (error) {
      emit(AuthFailure(error.message));
    } catch (_) {
      emit(
        AuthFailure(
          LanguageController.instance.translate(
            LanguageKeys.authenticationFailed,
          ),
        ),
      );
    }
  }
}
