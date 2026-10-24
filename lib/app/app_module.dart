import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_module.dart';
import '../features/home/home_module.dart';
import '../features/splash/presentation/ui/splash_page.dart';
import '../libraries/core/network/app_client.dart';
import '../libraries/core/storage/token_storage.dart';

class AppModule extends Module {
  final SharedPreferences prefs;

  AppModule(this.prefs);

  @override
  List<Bind> get binds => [
    Bind.instance<SharedPreferences>(prefs),

    Bind.lazySingleton<TokenStorage>((i) => TokenStorage(i.get())),

    Bind.lazySingleton<ApiClient>((i) => ApiClient(i.get())),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const SplashPage()),
    ModuleRoute('/auth', module: AuthModule()),
    ModuleRoute('/home', module: HomeModule()),
  ];
}
