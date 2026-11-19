/// Prioridade de uma tarefa. O [value] é o que fica salvo no banco.
enum TaskPriority {
  low(0, 'Baixa'),
  medium(1, 'Média'),
  high(2, 'Alta');

  final int value;
  final String label;

  const TaskPriority(this.value, this.label);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Tarefa pertencente a um usuário.
class Task {
  final int? id;
  final int userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;

  /// Duração estimada da tarefa, em minutos (opcional).
  final int? durationMinutes;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.durationMinutes,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromMap(Map<String, Object?> map) {
    final due = map['due_date'] as String?;
    return Task(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      priority: TaskPriority.fromValue(map['priority'] as int),
      dueDate: due == null ? null : DateTime.parse(due),
      durationMinutes: map['duration_minutes'] as int?,
      isDone: (map['is_done'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority.value,
      'due_date': dueDate?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    int? durationMinutes,
    bool clearDuration = false,
    bool? isDone,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      durationMinutes:
          clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Duração formatada para exibição, ex.: "1h 30min", "2h" ou "45min".
  String? get durationLabel {
    final total = durationMinutes;
    if (total == null || total <= 0) return null;
    final hours = total ~/ 60;
    final minutes = total % 60;
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  /// Verdadeiro se a tarefa não foi concluída e o prazo já passou.
  bool isOverdue([DateTime? now]) {
    if (isDone || dueDate == null) return false;
    final today = _dateOnly(now ?? DateTime.now());
    return _dateOnly(dueDate!).isBefore(today);
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
