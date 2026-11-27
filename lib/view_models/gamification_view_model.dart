import 'dart:math';

import 'package:flutter/material.dart';

import '../core/app_session.dart';
import '../core/database_helper.dart';
import '../core/game_rules.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

// Kết quả khi hoàn thành 1 nhắc nhở
class TaskRewardResult {
  final int gold;
  final int exp;
  final int hpGained;
  final bool onTime;

  TaskRewardResult({
    required this.gold,
    required this.exp,
    required this.hpGained,
    required this.onTime,
  });
}

// Kết quả xét các ngày đã qua (gọi khi đăng nhập)
class DayEvaluationSummary {
  int goodDays = 0; // Ngày có task và hoàn thành >= 1 -> streak +1
  int shieldUsed = 0; // Ngày bỏ lỡ nhưng được khiên bảo vệ
  int hpLost = 0; // Ngày bỏ lỡ, bị trừ máu
  bool streakLost = false; // Máu về 0 -> mất chuỗi

  bool get hasChanges =>
      goodDays > 0 || shieldUsed > 0 || hpLost > 0 || streakLost;

  String toMessage() {
    final parts = <String>[];
    if (goodDays > 0) parts.add('🔥 +$goodDays ngày chuỗi');
    if (shieldUsed > 0) parts.add('🛡️ Đã dùng $shieldUsed khiên');
    if (hpLost > 0) parts.add('💔 Mất $hpLost máu vì bỏ lỡ nhắc nhở');
    if (streakLost) parts.add('Hết máu, chuỗi đã bị reset!');
    return parts.join(' · ');
  }
}

// ViewModel xử lý toàn bộ luật Trò chơi hóa (Gamification)
//
// Luật:
// - Hoàn thành đúng hạn: +10 vàng, +1 HP (tối đa 3)
// - Hoàn thành trễ hạn:   +5 vàng, không hồi HP
// - Ngày không có nhắc nhở: không thay đổi gì
// - Ngày có nhắc nhở, hoàn thành >= 1: streak +1
// - Ngày có nhắc nhở, không hoàn thành việc nào:
//     có khiên -> tự tiêu 1 khiên, giữ nguyên HP và streak
//     không có -> -1 HP; HP về 0 thì streak = 0 và HP hồi đầy
class GamificationViewModel extends ChangeNotifier {
  UserModel? get user => AppSession.currentUser;

  Future<void> _saveUser(UserModel updated) async {
    AppSession.currentUser = updated;
    await DatabaseHelper.instance.updateUserStats(updated);
    notifyListeners();
    // Cập nhật widget ngoài màn hình chính (không chờ kết quả)
    WidgetService.update();
  }

  // ---------------- HOÀN THÀNH NHẮC NHỞ ----------------
  Future<TaskRewardResult?> completeTask(TaskModel task, DateTime date) async {
    final current = user;
    if (current == null || current.id == null || task.isDone) return null;

    final bool onTime = !task.isOverdue();
    final int gold = onTime ? GameRules.goldOnTime : GameRules.goldLate;
    final int hpBefore = current.hp;
    final int hpAfter = onTime
        ? min(hpBefore + GameRules.hpPerOnTimeTask, GameRules.maxHp)
        : hpBefore;

    await DatabaseHelper.instance.setTaskCompletionForDate(
      userId: current.id!,
      task: task,
      isDone: true,
      day: date.day,
      month: date.month,
      year: date.year,
    );
    task.isDone = true;

    // Đã hoàn thành -> hủy nhắc nhở; việc hàng ngày thì chuyển sang nhắc từ ngày mai
    if (task.id != null) {
      if (task.isDaily && task.reminderEnabled) {
        await NotificationService().scheduleTaskReminder(
          taskId: task.id!,
          title: task.title,
          category: task.category,
          timeHHmm: task.time,
          day: task.day,
          month: task.month,
          year: task.year,
          isDaily: true,
          description: task.description,
          skipToday: true,
        );
      } else {
        await NotificationService().cancelTaskReminder(task.id!);
      }
      // Đã xong -> không nhắc theo vị trí nữa
      if (task.hasLocation) LocationService().refresh();
    }

    await _saveUser(
      current.copyWith(
        gold: current.gold + gold,
        exp: current.exp + task.exp,
        hp: hpAfter,
      ),
    );

    return TaskRewardResult(
      gold: gold,
      exp: task.exp,
      hpGained: hpAfter - hpBefore,
      onTime: onTime,
    );
  }

  // ---------------- XÉT CÁC NGÀY ĐÃ QUA ----------------
  // Gọi ngay sau khi đăng nhập. Duyệt từng ngày từ lastCheckedDate + 1
  // đến hôm qua (hôm nay chưa kết thúc nên chưa xét).
  Future<DayEvaluationSummary> evaluatePastDays() async {
    final summary = DayEvaluationSummary();
    var current = user;
    if (current == null || current.id == null) return summary;

    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final yesterdayKey = db.formatDateKey(
      yesterday.day,
      yesterday.month,
      yesterday.year,
    );

    // Tài khoản cũ chưa có mốc xét -> bắt đầu xét từ hôm nay
    final lastKey = current.lastCheckedDate;
    if (lastKey == null || lastKey.isEmpty) {
      await _saveUser(current.copyWith(lastCheckedDate: yesterdayKey));
      return summary;
    }

    final last = DateTime.parse(lastKey);
    var day = DateTime(last.year, last.month, last.day + 1);

    int hp = current.hp;
    int shields = current.shields;
    int streak = current.currentStreak;
    int longest = current.longestStreak;

    while (day.isBefore(today)) {
      final tasks = await db.getTasksForDate(
        current.id!,
        day.day,
        day.month,
        day.year,
      );

      if (tasks.isEmpty) {
        // Ngày trung tính: không thưởng, không phạt
      } else if (tasks.any((t) => t.isDone)) {
        streak++;
        if (streak > longest) longest = streak;
        summary.goodDays++;
      } else if (shields > 0) {
        shields--;
        summary.shieldUsed++;
      } else {
        hp--;
        summary.hpLost++;
        if (hp <= 0) {
          streak = 0;
          hp = GameRules.maxHp;
          summary.streakLost = true;
        }
      }

      day = DateTime(day.year, day.month, day.day + 1);
    }

    current = current.copyWith(
      hp: hp,
      shields: shields,
      currentStreak: streak,
      longestStreak: longest,
      lastCheckedDate: yesterdayKey,
    );
    await _saveUser(current);
    return summary;
  }

  // ---------------- CỬA HÀNG ----------------
  // Trả về null nếu mua thành công, ngược lại trả về lý do thất bại
  Future<String?> buyShield() async {
    final current = user;
    if (current == null) return 'Chưa đăng nhập';
    if (current.shields >= GameRules.maxShields) {
      return 'Bạn chỉ được giữ tối đa ${GameRules.maxShields} khiên';
    }
    if (current.gold < GameRules.shieldPrice) return 'Không đủ vàng';

    await _saveUser(
      current.copyWith(
        gold: current.gold - GameRules.shieldPrice,
        shields: current.shields + 1,
      ),
    );
    return null;
  }

  Future<String?> redeemCustomReward() async {
    final current = user;
    if (current == null) return 'Chưa đăng nhập';
    if (current.gold < GameRules.customRewardPrice) return 'Không đủ vàng';

    await _saveUser(
      current.copyWith(gold: current.gold - GameRules.customRewardPrice),
    );
    return null;
  }

  // Hôm nay đã hoàn thành ít nhất 1 nhắc nhở chưa (để hiển thị trạng thái chuỗi)
  Future<bool> hasCompletedToday() async {
    final current = user;
    if (current == null || current.id == null) return false;
    final now = DateTime.now();
    final tasks = await DatabaseHelper.instance.getTasksForDate(
      current.id!,
      now.day,
      now.month,
      now.year,
    );
    return tasks.any((t) => t.isDone);
  }
}
