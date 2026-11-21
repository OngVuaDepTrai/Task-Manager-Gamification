import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../core/database_helper.dart';

// ViewModel xử lý logic nghiệp vụ cho Task theo chuẩn MVVM
class TaskViewModel extends ChangeNotifier {
  final List<TaskModel> _tasks = [];
  bool _isLoading = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // Lấy danh sách công việc từ Database
  Future<void> fetchTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tương lai sẽ gọi: _tasks = await DatabaseHelper.instance.getAllTasks();
      await Future.delayed(const Duration(milliseconds: 300)); // Giả lập load
    } catch (e) {
      debugPrint("Lỗi khi tải task: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Thêm công việc mới
  Future<void> addTask(TaskModel task) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tương lai sẽ gọi: await DatabaseHelper.instance.insertTask(task);
      _tasks.add(task);
    } catch (e) {
      debugPrint("Lỗi khi thêm task: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Đánh dấu hoàn thành
  void completeTask(int taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index].isDone = true;
      // Tại đây sẽ gọi GamificationViewModel để cộng điểm
      notifyListeners();
    }
  }
}
