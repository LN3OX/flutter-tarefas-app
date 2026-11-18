import 'package:material_ui/material_ui.dart';

/// Mensagem exibida quando não há tarefas para mostrar.
class EmptyState extends StatelessWidget {
  /// Se o usuário tem tarefas, mas o filtro/busca não encontrou nenhuma.
  final bool hasAnyTask;

  const EmptyState({super.key, required this.hasAnyTask});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ListView para o RefreshIndicator funcionar mesmo sem itens.
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(
          hasAnyTask ? Icons.search_off : Icons.checklist,
          size: 72,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          hasAnyTask
              ? 'Nenhuma tarefa encontrada'
              : 'Você ainda não tem tarefas',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          hasAnyTask
              ? 'Tente outro filtro ou termo de busca'
              : 'Toque em "Nova tarefa" para criar a primeira',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
