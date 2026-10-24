import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  final SharedPreferences prefs;

  TokenStorage(this.prefs);

  String? get accessToken => prefs.getString('access_token');
  String? get refreshToken => prefs.getString('refresh_token');

  Future<void> saveAccessToken(String token) async {
    await prefs.setString('access_token', token);
  }

  Future<void> saveRefreshToken(String token) async {
    await prefs.setString('refresh_token', token);
  }

  Future<void> clear() async {
    await prefs.clear();
  }
}
