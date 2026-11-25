import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_database/firebase_database.dart';

import '../../../shared/models/farm_task.dart';
import '../domain/task_repository.dart';

class RealtimeTaskRepository implements TaskRepository {
  RealtimeTaskRepository(this._database);

  final FirebaseDatabase _database;

  DatabaseReference _tasks(String ownerId) =>
      _database.ref('users').child(ownerId).child('tasks');

  DatabaseReference _task(FarmTask task) => _tasks(task.ownerId).child(task.id);

  @override
  Stream<List<FarmTask>> watchTasks(String ownerId) =>
      _tasks(ownerId).onValue.map((event) {
        final tasks = [
          for (final item in event.snapshot.children) _decode(item, ownerId),
        ];
        return tasks..sort((a, b) => a.dueAt.compareTo(b.dueAt));
      });

  FarmTask _decode(DataSnapshot item, String ownerId) {
    final data = Map<String, dynamic>.from(item.value as Map);
    for (final field in ['dueAt', 'createdAt', 'updatedAt', 'completedAt']) {
      final value = data[field];
      if (value != null) {
        data[field] = Timestamp.fromMillisecondsSinceEpoch(
          (value as num).toInt(),
        );
      }
    }
    data['ownerId'] = ownerId;
    return FarmTask.fromMap(item.key!, data);
  }

  Map<String, Object?> _editableFields(FarmTask task) => {
    'title': task.title,
    'description': task.description,
    'dueAt': task.dueAt.millisecondsSinceEpoch,
    'updatedAt': ServerValue.timestamp,
  };

  @override
  Future<void> createTask(FarmTask task) => _tasks(task.ownerId).push().set({
    ..._editableFields(task),
    'type': task.type,
    'priority': task.priority,
    'status': FarmTask.pendingStatus,
    'createdAt': ServerValue.timestamp,
  });

  @override
  Future<void> updateTask(FarmTask task) =>
      _task(task).update(_editableFields(task));

  @override
  Future<void> setTaskCompleted(FarmTask task, bool completed) =>
      _task(task).update({
        'status': completed ? FarmTask.completedStatus : FarmTask.pendingStatus,
        'completedAt': completed ? ServerValue.timestamp : null,
        'updatedAt': ServerValue.timestamp,
      });

  @override
  Future<void> deleteTask(FarmTask task) => _task(task).remove();
}
