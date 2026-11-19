import 'package:flutter/foundation.dart';

import '../models/task.dart';
import 'database_service.dart';

enum TaskFilter {
  all('Todas'),
  pending('Pendentes'),
  done('Concluídas');

  final String label;
  const TaskFilter(this.label);
}

/// Estado da lista de tarefas do usuário logado. A UI só conversa com esta
/// classe; o acesso ao SQLite fica no [DatabaseService].
class TaskService extends ChangeNotifier {
  final DatabaseService _db;

  int? _userId;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String _search = '';
  bool _loading = false;

  TaskService(this._db);

  bool get isLoading => _loading;
  TaskFilter get filter => _filter;
  List<Task> get allTasks => List.unmodifiable(_tasks);
  int get pendingCount => _tasks.where((t) => !t.isDone).length;
  int get doneCount => _tasks.where((t) => t.isDone).length;

  /// Tarefas após aplicar filtro e busca.
  List<Task> get visibleTasks {
    final query = _search.trim().toLowerCase();
    return _tasks.where((t) {
      final matchesFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.pending => !t.isDone,
        TaskFilter.done => t.isDone,
      };
      final matchesSearch = query.isEmpty ||
          t.title.toLowerCase().contains(query) ||
          t.description.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  Future<void> load(int userId) async {
    _userId = userId;
    _loading = true;
    notifyListeners();
    try {
      _tasks = await _db.getTasks(userId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (_userId != null) await load(_userId!);
  }

  Future<Task> create({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    int? durationMinutes,
  }) async {
    final now = DateTime.now();
    final task = await _db.insertTask(Task(
      userId: _requireUser(),
      title: title.trim(),
      description: description.trim(),
      priority: priority,
      dueDate: dueDate,
      durationMinutes: durationMinutes,
      createdAt: now,
      updatedAt: now,
    ));
    await reload();
    return task;
  }

  Future<void> update(Task task) async {
    _requireUser();
    await _db.updateTask(task.copyWith(
      title: task.title.trim(),
      description: task.description.trim(),
      updatedAt: DateTime.now(),
    ));
    await reload();
  }

  Future<void> toggleDone(Task task) => update(task.copyWith(isDone: !task.isDone));

  Future<void> delete(Task task) async {
    await _db.deleteTask(id: task.id!, userId: _requireUser());
    await reload();
  }

  /// Limpa o estado ao fazer logout.
  void clear() {
    _userId = null;
    _tasks = [];
    _filter = TaskFilter.all;
    _search = '';
    notifyListeners();
  }

  int _requireUser() {
    final id = _userId;
    if (id == null) throw StateError('Nenhum usuário carregado');
    return id;
  }
}
