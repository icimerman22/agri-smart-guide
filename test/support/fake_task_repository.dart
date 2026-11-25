import 'dart:async';

import 'package:agri_smart_guide/features/tasks/domain/task_repository.dart';
import 'package:agri_smart_guide/shared/models/farm_task.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class FakeTaskRepository implements TaskRepository {
  final _items = <String, Map<String, FarmTask>>{};
  final _changes = <String, StreamController<List<FarmTask>>>{};
  int _nextId = 0;
  bool failNextWrite = false;

  List<FarmTask> tasksFor(String uid) => _items[uid]?.values.toList() ?? [];

  bool isWatching(String uid) => _changes[uid]?.hasListener ?? false;

  @override
  Stream<List<FarmTask>> watchTasks(String ownerId) => Stream.multi((listener) {
    final updates = _changes.putIfAbsent(ownerId, StreamController.broadcast);
    final subscription = updates.stream.listen(listener.add);
    listener.onCancel = subscription.cancel;
    listener.add(tasksFor(ownerId));
  });

  void _apply(FarmTask task, void Function(Map<String, FarmTask>) change) {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Permission denied');
    }
    change(_items.putIfAbsent(task.ownerId, () => {}));
    _changes[task.ownerId]?.add(tasksFor(task.ownerId));
  }

  @override
  Future<void> createTask(FarmTask task) async => _apply(task, (items) {
    final id = (++_nextId).toString();
    items[id] = FarmTask.fromMap(id, task.toMap());
  });

  @override
  Future<void> updateTask(FarmTask task) async => _apply(task, (items) {
    items[task.id] = FarmTask.fromMap(task.id, {
      ...items[task.id]!.toMap(),
      'title': task.title,
      'description': task.description,
      'dueAt': task.dueAt,
    });
  });

  @override
  Future<void> setTaskCompleted(FarmTask task, bool completed) async => _apply(
    task,
    (items) {
      items[task.id] = FarmTask.fromMap(task.id, {
        ...items[task.id]!.toMap(),
        'status': completed ? FarmTask.completedStatus : FarmTask.pendingStatus,
        'completedAt': completed ? Timestamp.now() : null,
      });
    },
  );

  @override
  Future<void> deleteTask(FarmTask task) async =>
      _apply(task, (items) => items.remove(task.id));
}
