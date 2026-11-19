import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../utils/validators.dart';
import '../widgets/confirm_dialog.dart';

/// Formulário de criação (Create) e edição (Update) de tarefa.
/// Recebe a tarefa como argumento da rota quando é edição.
class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late TaskPriority _priority;
  DateTime? _dueDate;
  late bool _isDone;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    final duration = task?.durationMinutes;
    _hoursController = TextEditingController(
        text: duration == null || duration ~/ 60 == 0 ? '' : '${duration ~/ 60}');
    _minutesController = TextEditingController(
        text: duration == null || duration % 60 == 0 ? '' : '${duration % 60}');
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
    _isDone = task?.isDone ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  /// Converte os campos de horas e minutos em minutos totais
  /// (null quando nenhuma duração foi informada).
  int? get _durationInMinutes {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final total = hours * 60 + minutes;
    return total > 0 ? total : null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Selecione o prazo',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final service = context.read<TaskService>();
    try {
      if (_isEditing) {
        await service.update(widget.task!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
          durationMinutes: _durationInMinutes,
          clearDuration: _durationInMinutes == null,
          isDone: _isDone,
        ));
      } else {
        await service.create(
          title: _titleController.text,
          description: _descriptionController.text,
          priority: _priority,
          dueDate: _dueDate,
          durationMinutes: _durationInMinutes,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Tarefa atualizada' : 'Tarefa criada'),
      ));
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Erro: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar a tarefa')),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Excluir tarefa',
      message: 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed || !mounted) return;
    await context.read<TaskService>().delete(widget.task!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarefa excluída')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
        actions: [
          if (_isEditing)
            IconButton(
              key: const Key('delete_task_button'),
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('task_title'),
                    controller: _titleController,
                    validator: Validators.taskTitle,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('task_description'),
                    controller: _descriptionController,
                    validator: Validators.taskDescription,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskPriority>(
                    key: const Key('task_priority'),
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: [
                      for (final p in TaskPriority.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (p) => setState(() => _priority = p!),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Prazo',
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_dueDate == null
                              ? 'Sem prazo'
                              : _dateFormat.format(_dueDate!)),
                        ),
                        TextButton(
                          key: const Key('task_pick_date'),
                          onPressed: _pickDate,
                          child: const Text('Escolher'),
                        ),
                        if (_dueDate != null)
                          IconButton(
                            tooltip: 'Remover prazo',
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Duração',
                      prefixIcon: Icon(Icons.timer_outlined),
                      helperText: 'Opcional. Tempo estimado para fazer a tarefa.',
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('task_duration_hours'),
                            controller: _hoursController,
                            validator: Validators.durationHours,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Horas',
                              suffixText: 'h',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('task_duration_minutes'),
                            controller: _minutesController,
                            validator: Validators.durationMinutes,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Minutos',
                              suffixText: 'min',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const Key('task_done_switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Concluída'),
                      value: _isDone,
                      onChanged: (v) => setState(() => _isDone = v),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('task_save'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isEditing ? 'Salvar alterações' : 'Criar tarefa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
