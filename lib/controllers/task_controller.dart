import 'package:get/get.dart';
import 'package:todo/db/db_helper.dart';
import 'package:todo/models/task.dart';

class TaskController extends GetxController {
  final RxList<Task> taskList = <Task>[].obs;
  addTask({Task? task}) {
    return DBHelper.insert(task);
  }

  Future<void> getTasks() async {
    print('Getting it...');
    final List<Map<String, dynamic>> tasks = await DBHelper.query();
    taskList.assignAll(tasks.map((data) => Task.fromJson(data)).toList());
  }

  void deleteTasks(Task task) async {
    await DBHelper.delete(task);
    getTasks();
  }
  void deleteAllTasks() async {
    await DBHelper.deleteAll();
    getTasks();
  }

  void markTasksCompleted(int id) async {
    await DBHelper.update(id);
    getTasks();
  }
}
