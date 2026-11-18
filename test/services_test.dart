import 'package:flutter_test/flutter_test.dart';
import 'package:tarefas_app/models/task.dart';
import 'package:tarefas_app/services/auth_service.dart';
import 'package:tarefas_app/services/database_service.dart';
import 'package:tarefas_app/services/task_service.dart';

import 'test_helpers.dart';

void main() {
  late DatabaseService db;
  late AuthService auth;

  setUp(() async {
    db = createTestDatabase();
    auth = AuthService(db);
    await auth.init();
  });

  tearDown(() => db.close());

  group('AuthService', () {
    test('cadastro cria usuário logado e guarda só o hash da senha', () async {
      final user = await auth.register(
          name: 'Ana Souza', email: ' Ana@Email.com ', password: 'segredo1');

      expect(auth.isAuthenticated, isTrue);
      expect(user.email, 'ana@email.com');
      expect(user.passwordHash, isNot(contains('segredo1')));
      expect(user.passwordHash,
          AuthService.hashPassword('segredo1', user.salt));
    });

    test('e-mail duplicado é rejeitado', () async {
      await auth.register(name: 'Ana', email: 'ana@email.com', password: '123456');
      await auth.logout();
      expect(
        () => auth.register(name: 'Outra', email: 'ANA@email.com', password: 'abcdef'),
        throwsA(isA<AuthException>().having(
            (e) => e.message, 'message', 'Este e-mail já está cadastrado')),
      );
    });

    test('login válido, senha errada, e-mail inexistente e campos vazios',
        () async {
      await auth.register(name: 'Ana', email: 'ana@email.com', password: '123456');
      await auth.logout();
      expect(auth.isAuthenticated, isFalse);

      final invalid = throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', 'E-mail ou senha inválidos'));
      expect(() => auth.login(email: 'ana@email.com', password: 'errada'), invalid);
      expect(() => auth.login(email: 'nao@existe.com', password: '123456'), invalid);
      expect(() => auth.login(email: '', password: ''),
          throwsA(isA<AuthException>()));

      await auth.login(email: 'ana@email.com', password: '123456');
      expect(auth.currentUser?.name, 'Ana');
    });

    test('sessão é restaurada ao reabrir o app e removida no logout', () async {
      await auth.register(name: 'Ana', email: 'ana@email.com', password: '123456');

      final reopened = AuthService(db);
      await reopened.init();
      expect(reopened.currentUser?.email, 'ana@email.com');

      await reopened.logout();
      final afterLogout = AuthService(db);
      await afterLogout.init();
      expect(afterLogout.isAuthenticated, isFalse);
    });
  });

  group('TaskService (CRUD)', () {
    test('criar, listar, atualizar e excluir tarefas', () async {
      final user = await auth.register(
          name: 'Ana', email: 'ana@email.com', password: '123456');
      final service = TaskService(db);
      await service.load(user.id!);
      expect(service.allTasks, isEmpty);

      // Create
      await service.create(
          title: 'Estudar Flutter',
          description: 'Rotas e Provider',
          priority: TaskPriority.high,
          dueDate: DateTime(2030, 1, 10));
      await service.create(title: 'Comprar pão', priority: TaskPriority.low);

      // Read
      expect(service.allTasks.map((t) => t.title),
          ['Estudar Flutter', 'Comprar pão']); // ordenado por prioridade
      final saved = service.allTasks.first;
      expect(saved.description, 'Rotas e Provider');
      expect(saved.dueDate, DateTime(2030, 1, 10));

      // Update
      await service.update(saved.copyWith(title: 'Estudar Dart', clearDueDate: true));
      await service.toggleDone(service.allTasks.firstWhere((t) => t.title == 'Comprar pão'));
      expect(service.allTasks.any((t) => t.title == 'Estudar Dart' && t.dueDate == null),
          isTrue);
      expect(service.doneCount, 1);
      expect(service.pendingCount, 1);

      // Filtro e busca
      service.setFilter(TaskFilter.done);
      expect(service.visibleTasks.single.title, 'Comprar pão');
      service.setFilter(TaskFilter.all);
      service.setSearch('dart');
      expect(service.visibleTasks.single.title, 'Estudar Dart');
      service.setSearch('');

      // Delete
      await service.delete(service.allTasks.first);
      expect(service.allTasks, hasLength(1));
    });

    test('um usuário não vê nem altera tarefas de outro', () async {
      final ana = await auth.register(
          name: 'Ana', email: 'ana@email.com', password: '123456');
      final service = TaskService(db);
      await service.load(ana.id!);
      await service.create(title: 'Tarefa da Ana');
      final anaTask = service.allTasks.single;

      await auth.logout();
      final bruno = await auth.register(
          name: 'Bruno', email: 'bruno@email.com', password: '123456');
      await service.load(bruno.id!);
      expect(service.allTasks, isEmpty);

      // Tentativa de excluir a tarefa da Ana estando logado como Bruno.
      expect(await db.deleteTask(id: anaTask.id!, userId: bruno.id!), 0);
      expect(await db.getTasks(ana.id!), hasLength(1));
    });
  });

  test('Task.isOverdue', () {
    final base = Task(
      userId: 1,
      title: 'x',
      dueDate: DateTime(2026, 1, 1),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    expect(base.isOverdue(DateTime(2026, 1, 2)), isTrue);
    expect(base.isOverdue(DateTime(2026, 1, 1, 23)), isFalse);
    expect(base.copyWith(isDone: true).isOverdue(DateTime(2027)), isFalse);
  });
}
