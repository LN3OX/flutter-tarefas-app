import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tarefas_app/main.dart';
import 'package:tarefas_app/services/auth_service.dart';
import 'package:tarefas_app/services/database_service.dart';

import 'test_helpers.dart';

/// Testes de interface cobrindo o fluxo completo do usuário.
void main() {
  late DatabaseService db;
  late AuthService auth;

  Future<void> pumpApp(WidgetTester tester) async {
    // Tela com proporção de celular.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      db = createTestDatabase();
      auth = AuthService(db);
      await auth.init();
    });
    await tester.pumpWidget(TarefasApp(database: db, auth: auth));
    await tester.pumpAndSettle();
  }

  /// Operações do SQLite rodam fora do relógio falso dos testes de widget.
  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('abre no login e valida campos vazios', (tester) async {
    await pumpApp(tester);

    expect(find.text('Entrar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('E-mail é obrigatório'), findsOneWidget);
    expect(find.text('Senha é obrigatória'), findsOneWidget);
  });

  testWidgets('login inválido mostra mensagem de erro', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byKey(const Key('login_email')), 'x@y.com');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const Key('login_password')),
            matching: find.byType(TextField)),
        '123456');
    await tapAndWait(tester, find.byKey(const Key('login_submit')));

    expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
  });

  testWidgets('cadastro → CRUD de tarefa → logout protege a home',
      (tester) async {
    await pumpApp(tester);

    // Cadastro
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('register_name')), 'Ana Souza');
    await tester.enterText(
        find.byKey(const Key('register_email')), 'ana@email.com');
    Finder pwd(String key) => find.descendant(
        of: find.byKey(Key(key)), matching: find.byType(TextField));
    await tester.enterText(pwd('register_password'), '123456');
    await tester.enterText(pwd('register_confirm'), '654321');
    await tester.tap(find.byKey(const Key('register_submit')));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não coincidem'), findsOneWidget);

    await tester.enterText(pwd('register_confirm'), '123456');
    await tapAndWait(tester, find.byKey(const Key('register_submit')));

    // Home
    expect(find.text('Olá, Ana'), findsOneWidget);
    expect(find.text('Você ainda não tem tarefas'), findsOneWidget);

    // Create (com validação)
    await tester.tap(find.byKey(const Key('add_task_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_save')));
    await tester.pumpAndSettle();
    expect(find.text('Título é obrigatório'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('task_title')), 'Entregar trabalho');
    await tester.enterText(
        find.byKey(const Key('task_description')), 'Projeto Flutter');
    await tapAndWait(tester, find.byKey(const Key('task_save')));

    // Read
    expect(find.text('Entregar trabalho'), findsOneWidget);
    expect(find.text('Projeto Flutter'), findsOneWidget);

    // Update: abre a edição, altera título e marca como concluída
    await tester.tap(find.text('Entregar trabalho'));
    await tester.pumpAndSettle();
    expect(find.text('Editar tarefa'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('task_title')), 'Trabalho entregue');
    await tester.tap(find.byKey(const Key('task_done_switch')));
    await tapAndWait(tester, find.byKey(const Key('task_save')));
    expect(find.text('Trabalho entregue'), findsOneWidget);
    expect(find.text('Concluídas (1)'), findsOneWidget);

    // Delete
    await tester.tap(find.byTooltip('Excluir'));
    await tester.pumpAndSettle();
    await tapAndWait(tester, find.widgetWithText(FilledButton, 'Excluir'));
    expect(find.text('Trabalho entregue'), findsNothing);
    expect(find.text('Você ainda não tem tarefas'), findsOneWidget);

    // Logout
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    await tapAndWait(tester, find.widgetWithText(FilledButton, 'Sair'));
    expect(find.text('Entrar'), findsOneWidget);
    expect(auth.isAuthenticated, isFalse);

    // Proteção: tentar abrir a home sem login redireciona para o login
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/home');
    await tester.pumpAndSettle();
    expect(find.text('Olá, Ana'), findsNothing);
    expect(find.text('Entrar'), findsWidgets);
  });
}
