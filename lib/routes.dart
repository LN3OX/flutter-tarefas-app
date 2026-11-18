import 'package:material_ui/material_ui.dart';

import 'models/task.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/task_form_screen.dart';
import 'services/auth_service.dart';

/// Nomes das rotas do app.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const taskForm = '/task-form';

  /// Rotas que exigem usuário autenticado.
  static const protectedRoutes = {home, taskForm};
}

/// Gera as rotas aplicando a proteção de telas:
/// - rota protegida sem login → redireciona para o login;
/// - login/cadastro já autenticado → redireciona para a home.
Route<dynamic> generateRoute(RouteSettings settings, AuthService auth) {
  var name = settings.name ?? AppRoutes.login;

  if (AppRoutes.protectedRoutes.contains(name) && !auth.isAuthenticated) {
    name = AppRoutes.login;
  } else if ((name == AppRoutes.login || name == AppRoutes.register) &&
      auth.isAuthenticated) {
    name = AppRoutes.home;
  }

  final Widget page = switch (name) {
    AppRoutes.register => const RegisterScreen(),
    AppRoutes.home => const HomeScreen(),
    AppRoutes.taskForm => TaskFormScreen(task: settings.arguments as Task?),
    _ => const LoginScreen(),
  };

  return MaterialPageRoute(
    settings: RouteSettings(name: name, arguments: settings.arguments),
    builder: (_) => page,
  );
}
