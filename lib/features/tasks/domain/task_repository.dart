import '../../../shared/models/farm_task.dart';

abstract interface class TaskRepository {
  Stream<List<FarmTask>> watchTasks(String ownerId);
  Future<void> createTask(FarmTask task);
  Future<void> updateTask(FarmTask task);
  Future<void> setTaskCompleted(FarmTask task, bool completed);
  Future<void> deleteTask(FarmTask task);
}
