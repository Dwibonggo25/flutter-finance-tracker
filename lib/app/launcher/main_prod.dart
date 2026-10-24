import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../libraries/core/config/app_config.dart';
import '../../libraries/core/firebase/firebase_config.dart';
import '../../libraries/core/localization/language_controller.dart';
import '../../libraries/core/notifications/local_notification_service.dart';
import '../../libraries/core/theme/theme_controller.dart';
import '../app_module.dart';
import '../app_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  LanguageController.instance.initialize(prefs);
  ThemeController.instance.initialize(prefs);

  AppConfig.init(Flavor.prod);
  await FirebaseConfig.initialize();
  await LocalNotificationService.instance.initialize();

  runApp(ModularApp(module: AppModule(prefs), child: const AppWidget()));
}
