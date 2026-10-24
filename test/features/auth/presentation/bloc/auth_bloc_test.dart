import 'package:finance_project/features/auth/domain/repositories/auth_repository.dart';
import 'package:finance_project/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:finance_project/features/auth/presentation/bloc/auth_event.dart';
import 'package:finance_project/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthBloc', () {
    test('emits authenticated when login succeeds', () async {
      final repository = _FakeAuthRepository();
      final bloc = AuthBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([const AuthLoading(), const AuthAuthenticated()]),
      );

      bloc.add(
        const AuthLoginSubmitted(
          email: 'dwi@example.com',
          password: 'secret123',
        ),
      );

      await expectation;
      expect(repository.lastSignedInEmail, 'dwi@example.com');
      await bloc.close();
    });

    test('emits readable failure when login is rejected', () async {
      final repository = _FakeAuthRepository(
        failure: const AuthenticationFailure('Email atau kata sandi salah.'),
      );
      final bloc = AuthBloc(repository);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthFailure('Email atau kata sandi salah.'),
        ]),
      );

      bloc.add(
        const AuthLoginSubmitted(
          email: 'dwi@example.com',
          password: 'wrong-password',
        ),
      );

      await expectation;
      await bloc.close();
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  final AuthenticationFailure? failure;

  String? lastSignedInEmail;

  _FakeAuthRepository({this.failure});

  @override
  bool get hasSignedInUser => false;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (failure != null) throw failure!;
    lastSignedInEmail = email;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {}
}
