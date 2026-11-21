import 'package:flutter/material.dart';

import '../core/app_session.dart';

// ViewModel xử lý logic Trò chơi hóa (Gamification)
class GamificationViewModel extends ChangeNotifier {
  // Xử lý cộng điểm khi hoàn thành Task
  void rewardUser({required int exp, required int gold}) {
    if (AppSession.currentUser != null) {
      // Tương lai: Cập nhật vào SQLite
      // AppSession.currentUser!.exp += exp;
      // AppSession.currentUser!.gold += gold;
      notifyListeners();
    }
  }

  // Xử lý trừ HP khi trễ hạn task
  void punishUser(int hpDeduction) {
    // Logic trừ HP nhân vật
    notifyListeners();
  }

  // Cập nhật Chuỗi (Streak)
  void updateStreak(bool isTaskCompletedToday, bool hasStreakFreeze) {
    if (AppSession.currentUser != null) {
      if (isTaskCompletedToday) {
        // Tăng chuỗi
      } else {
        if (hasStreakFreeze) {
          // Tiêu thụ khiên bảo vệ, giữ nguyên chuỗi
        } else {
          // Mất chuỗi, reset về 0
        }
      }
      notifyListeners();
    }
  }
}
