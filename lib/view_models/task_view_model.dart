import 'package:flutter/foundation.dart';

import '../core/database_helper.dart';
import '../core/app_session.dart';
import '../models/task_model.dart';
import '../services/game_store.dart';

class TaskViewModel extends ChangeNotifier {
  Future<List<TaskModel>> forDay(DateTime date) =>
      DatabaseHelper.instance.getTasksForDate(
        AppSession.currentUser!.id!,
        date.day,
        date.month,
        date.year,
      );
  Future<bool> setDone(TaskModel task, bool done, DateTime now) async {
    final id = AppSession.currentUser!.id!;
    return GameStore.complete(
      await DatabaseHelper.instance.database,
      id,
      task.id!,
      done,
      now,
    );
  }
}
