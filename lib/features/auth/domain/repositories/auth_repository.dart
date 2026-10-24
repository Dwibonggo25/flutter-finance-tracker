abstract class AuthRepository {
  bool get hasSignedInUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}

class AuthenticationFailure implements Exception {
  final String message;

  const AuthenticationFailure(this.message);

  @override
  String toString() => message;
}
