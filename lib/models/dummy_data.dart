import 'task_model.dart';

class DummyData {
  // Danh sách RỖNG hoàn toàn cho user mới đăng ký
  static List<TaskModel> allTasks = [];

  static List<TaskModel> getTasksByDay(int day) {
    return allTasks.where((task) => task.day == day).toList();
  }

  // Hàm thêm công việc mới (Dùng cho lúc Demo báo cáo)
  static void addTask(TaskModel task) {
    allTasks.add(task);
  }
}
