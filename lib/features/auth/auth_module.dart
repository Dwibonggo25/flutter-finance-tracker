import 'package:flutter_modular/flutter_modular.dart';

import 'data/repositories/firebase_auth_repository.dart';
import 'domain/repositories/auth_repository.dart';
import 'presentation/bloc/auth_bloc.dart';
import 'presentation/ui/login_page.dart';

class AuthModule extends Module {
  @override
  List<Bind> get binds => [
    Bind.lazySingleton<AuthRepository>((i) => FirebaseAuthRepository()),
    Bind.factory<AuthBloc>((i) => AuthBloc(i.get<AuthRepository>())),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (_, __) => const LoginPage()),
  ];
}
