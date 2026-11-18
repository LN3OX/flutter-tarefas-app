import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/task_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DatabaseService();
  final auth = AuthService(database);
  await auth.init(); // restaura a sessão, se existir

  runApp(TarefasApp(database: database, auth: auth));
}

class TarefasApp extends StatelessWidget {
  final DatabaseService database;
  final AuthService auth;

  const TarefasApp({super.key, required this.database, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: database),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<TaskService>(
          create: (_) => TaskService(database),
        ),
      ],
      child: MaterialApp(
        title: 'Minhas Tarefas',
        debugShowCheckedModeBanner: false,
        // Textos padrão do Material (ex.: seletor de data) em português.
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        initialRoute: auth.isAuthenticated ? AppRoutes.home : AppRoutes.login,
        onGenerateRoute: (settings) => generateRoute(settings, auth),
        // Gera só a rota inicial pedida (sem empilhar "/" por baixo), também
        // aplicando a proteção quando a URL é digitada no navegador.
        onGenerateInitialRoutes: (initialRoute) =>
            [generateRoute(RouteSettings(name: initialRoute), auth)],
      ),
    );
  }
}
