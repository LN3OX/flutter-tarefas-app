import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../routes.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_tile.dart';

/// Tela principal: lista (Read) das tarefas, com filtro, busca, marcação de
/// concluída (Update), exclusão (Delete) e botão para criar (Create).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _guard(() => context.read<TaskService>().load(user.id!)),
      );
    }
  }

  /// Executa uma operação no banco mostrando um aviso se ela falhar.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('Erro: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao acessar o banco de dados')),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sair',
      message: 'Deseja encerrar a sessão?',
      confirmLabel: 'Sair',
    );
    if (!confirmed || !mounted) return;
    context.read<TaskService>().clear();
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _delete(Task task) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir tarefa',
      message: 'Excluir "${task.title}"? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed || !mounted) return;
    await _guard(() => context.read<TaskService>().delete(task));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarefa excluída')),
    );
  }

  void _openForm([Task? task]) {
    Navigator.pushNamed(context, AppRoutes.taskForm, arguments: task);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final tasks = context.watch<TaskService>();
    final visible = tasks.visibleTasks;

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.firstName ?? ''}'),
        actions: [
          IconButton(
            key: const Key('logout_button'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_task_button'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nova tarefa'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  key: const Key('search_field'),
                  onChanged: tasks.setSearch,
                  decoration: const InputDecoration(
                    hintText: 'Buscar tarefas',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TaskFilter>(
                    segments: [
                      for (final f in TaskFilter.values)
                        ButtonSegment(
                          value: f,
                          label: Text(switch (f) {
                            TaskFilter.all =>
                              '${f.label} (${tasks.allTasks.length})',
                            TaskFilter.pending =>
                              '${f.label} (${tasks.pendingCount})',
                            TaskFilter.done => '${f.label} (${tasks.doneCount})',
                          }),
                        ),
                    ],
                    selected: {tasks.filter},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => tasks.setFilter(s.first),
                  ),
                ),
              ),
              Expanded(
                child: tasks.isLoading && tasks.allTasks.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => _guard(tasks.reload),
                        child: visible.isEmpty
                            ? EmptyState(
                                hasAnyTask: tasks.allTasks.isNotEmpty,
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 88),
                                itemCount: visible.length,
                                itemBuilder: (context, i) {
                                  final task = visible[i];
                                  return TaskTile(
                                    key: ValueKey(task.id),
                                    task: task,
                                    onToggle: () =>
                                        _guard(() => tasks.toggleDone(task)),
                                    onTap: () => _openForm(task),
                                    onDelete: () => _delete(task),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
