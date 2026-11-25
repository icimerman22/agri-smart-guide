import 'package:flutter/material.dart';

import '../../../shared/formatters/date_format.dart';
import '../../../shared/models/farm_task.dart';
import '../../auth/domain/auth_service.dart';
import '../domain/task_repository.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({
    super.key,
    required this.authService,
    required this.ownerId,
    required this.repository,
  });

  final AuthService authService;
  final String ownerId;
  final TaskRepository repository;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Stream<List<FarmTask>> _tasks = widget.repository.watchTasks(
    widget.ownerId,
  );
  final _savingTasks = <String>{};

  bool get _hasSession => widget.authService.currentUser?.uid == widget.ownerId;

  void _openForm({FarmTask? task}) {
    if (!_hasSession) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskFormScreen(
          ownerId: widget.ownerId,
          taskToEdit: task,
          onSave: (edited) async {
            if (!mounted || !_hasSession) {
              throw const AuthException('no-current-user');
            }
            if (task == null) {
              await widget.repository.createTask(edited);
            } else {
              await widget.repository.updateTask(edited);
            }
          },
        ),
      ),
    );
  }

  Future<void> _writeTask(
    FarmTask task,
    Future<void> Function() write,
    String error,
  ) async {
    if (!_hasSession || _savingTasks.contains(task.id)) return;

    setState(() => _savingTasks.add(task.id));
    try {
      await write();
    } catch (_) {
      if (mounted && _hasSession) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    } finally {
      if (mounted) setState(() => _savingTasks.remove(task.id));
    }
  }

  Future<void> _confirmDelete(FarmTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Brisanje zadatka'),
        content: Text('Želite li obrisati zadatak „${task.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    await _writeTask(
      task,
      () => widget.repository.deleteTask(task),
      'Brisanje zadatka nije uspjelo.',
    );
  }

  Widget _buildList(List<FarmTask> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Nemate dodanih zadataka.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final task = items[index];
        final date = formatShortDate(task.dueAt.toDate().toUtc());
        final isSaving = _savingTasks.contains(task.id);
        final status = isSaving
            ? 'Spremanje…'
            : task.isCompleted
            ? 'Izvršen'
            : 'Neizvršen';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: Tooltip(
              message: task.isCompleted
                  ? 'Poništi izvršenje'
                  : 'Označi izvršenim',
              child: Checkbox(
                value: task.isCompleted,
                onChanged: isSaving
                    ? null
                    : (value) => _writeTask(
                        task,
                        () => widget.repository.setTaskCompleted(
                          task,
                          value == true,
                        ),
                        'Promjena statusa zadatka nije uspjela.',
                      ),
              ),
            ),
            title: Text(task.title),
            subtitle: Text(
              task.description.isEmpty
                  ? '$date • $status'
                  : '$date • $status\n${task.description}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: task.description.isNotEmpty,
            onTap: isSaving ? null : () => _openForm(task: task),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Obriši zadatak',
              onPressed: isSaving ? null : () => _confirmDelete(task),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSession) {
      return const Scaffold(
        body: Center(child: Text('Korisnik nije prijavljen.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Zadaci')),
      body: StreamBuilder<List<FarmTask>>(
        stream: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Učitavanje zadataka nije uspjelo.'),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _tasks = widget.repository.watchTasks(widget.ownerId);
                    }),
                    child: const Text('Pokušaj ponovno'),
                  ),
                ],
              ),
            );
          }
          return _buildList(snapshot.data ?? const []);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: 'Dodaj zadatak',
        child: const Icon(Icons.add),
      ),
    );
  }
}
