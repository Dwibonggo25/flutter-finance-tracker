import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/app_client.dart';

import '../core/storage/token_storage.dart';

class Injection {
  static List<Bind> get binds => [
    // TokenStorage
    Bind.lazySingleton<TokenStorage>(
      (i) => TokenStorage(i.get<SharedPreferences>()),
    ),

    // ApiClient
    Bind.lazySingleton<ApiClient>((i) => ApiClient(i.get<TokenStorage>())),
  ];
}
