import 'package:flutter/material.dart';

import '../../../shared/formatters/date_format.dart';
import '../../../shared/models/farm_task.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key, required this.ownerId, required this.tasks});

  final String ownerId;
  final ValueNotifier<List<FarmTask>> tasks;

  Future<void> _openForm(BuildContext context, {FarmTask? task}) async {
    final saved = await Navigator.of(context).push<FarmTask>(
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(ownerId: ownerId, taskToEdit: task),
      ),
    );
    if (!context.mounted || saved == null) return;

    tasks.value = [
      for (final existing in tasks.value) existing == task ? saved : existing,
      if (task == null) saved,
    ];
  }

  Future<void> _confirmDelete(BuildContext context, FarmTask task) async {
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
    if (!context.mounted || confirmed != true) return;

    tasks.value = [
      for (final existing in tasks.value)
        if (existing != task) existing,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zadaci')),
      body: ValueListenableBuilder<List<FarmTask>>(
        valueListenable: tasks,
        builder: (context, items, _) {
          if (items.isEmpty) {
            return const Center(child: Text('Nemate dodanih zadataka.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final task = items[index];
              final date = formatShortDate(task.dueAt.toDate());
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(task.title),
                  subtitle: Text(
                    task.description.isEmpty
                        ? date
                        : '$date\n${task.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: task.description.isNotEmpty,
                  onTap: () => _openForm(context, task: task),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Obriši zadatak',
                    onPressed: () => _confirmDelete(context, task),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        tooltip: 'Dodaj zadatak',
        child: const Icon(Icons.add),
      ),
    );
  }
}
