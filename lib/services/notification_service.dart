import 'package:flutter/foundation.dart';

// Service chuyên xử lý thông báo nhắc nhở công việc theo giờ
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<Map<String, dynamic>> _scheduledReminders = [];

  List<Map<String, dynamic>> get scheduledReminders =>
      List.unmodifiable(_scheduledReminders);

  Future<void> initService() async {
    debugPrint("Đã khởi tạo NotificationService (Nhắc nhở công việc).");
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required String category,
    required String timeHHmm,
    required int day,
    required int month,
    required int year,
    required bool isDaily,
  }) async {
    final parts = timeHHmm.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final now = DateTime.now();
    var targetTime = DateTime(year, month, day, hour, minute);
    if (isDaily && targetTime.isBefore(now)) {
      targetTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    }

    _scheduledReminders.removeWhere((item) => item['taskId'] == taskId);
    _scheduledReminders.add({
      'taskId': taskId,
      'title': title,
      'category': category,
      'scheduledAt': targetTime,
      'isDaily': isDaily,
    });

    debugPrint(
      "Đã đặt nhắc nhở [$title] ($category) vào lúc $targetTime (Hàng ngày: $isDaily)",
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    _scheduledReminders.removeWhere((item) => item['taskId'] == taskId);
    debugPrint("Đã hủy nhắc nhở cho taskId=$taskId");
  }

  Future<void> scheduleAlarm(
    DateTime scheduledTime,
    String title,
    String body,
  ) async {
    debugPrint("Đã lên lịch nhắc nhở vào lúc: $scheduledTime - $title");
  }

  Future<void> showNotification(String title, String body) async {
    debugPrint("Nhắc nhở: $title - $body");
  }
}
