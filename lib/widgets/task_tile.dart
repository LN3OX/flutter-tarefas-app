import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/task.dart';

/// Item da lista de tarefas.
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  Color _priorityColor(ColorScheme scheme) => switch (task.priority) {
        TaskPriority.high => scheme.error,
        TaskPriority.medium => Colors.orange,
        TaskPriority.low => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = task.isOverdue();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? theme.disabledColor : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(task.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                _Badge(
                  icon: Icons.flag,
                  text: task.priority.label,
                  color: _priorityColor(theme.colorScheme),
                ),
                if (task.durationLabel != null)
                  _Badge(
                    icon: Icons.timer_outlined,
                    text: task.durationLabel!,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                if (task.dueDate != null)
                  _Badge(
                    icon: Icons.event,
                    text: overdue
                        ? 'Atrasada · ${_dateFormat.format(task.dueDate!)}'
                        : _dateFormat.format(task.dueDate!),
                    color: overdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Badge({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
