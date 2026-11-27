import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/database_helper.dart';

// Service thông báo nhắc nhở công việc (dùng flutter_local_notifications).
//
// Thông báo được hệ điều hành lên lịch (AlarmManager trên Android), nên
// vẫn hiện đúng giờ kể cả khi người dùng đã tắt ứng dụng.
// ID thông báo = ID của task, để có thể hủy / đặt lại theo từng task.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _canScheduleExact = false;

  static const String _channelId = 'task_reminders';
  static const String _channelName = 'Nhắc nhở công việc';
  static const String _channelDesc = 'Thông báo nhắc việc theo giờ và vị trí';

  // ID dành riêng cho thông báo tức thời (GPS), tránh trùng ID task
  static const int _instantIdBase = 900000;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentSound: true,
    ),
  );

  // Gọi 1 lần trong main()
  Future<void> initService() async {
    if (_initialized || !_isSupported) return;
    try {
      tzdata.initializeTimeZones();
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint("Không khởi tạo được NotificationService: $e");
    }
  }

  // Xin quyền thông báo (Android 13+ / iOS). Gọi sau khi đăng nhập.
  Future<void> requestPermissions() async {
    if (!_initialized) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      _canScheduleExact =
          await android.canScheduleExactNotifications() ?? false;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Đặt lịch nhắc cho 1 task.
  // - Task thường: nhắc 1 lần đúng ngày giờ đến hạn (bỏ qua nếu đã qua).
  // - Task hàng ngày: lặp lại mỗi ngày vào giờ đã chọn.
  //   skipToday = true khi hôm nay đã làm xong -> bắt đầu nhắc từ ngày mai.
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String title,
    required String category,
    required String timeHHmm,
    required int day,
    required int month,
    required int year,
    required bool isDaily,
    String? description,
    bool skipToday = false,
  }) async {
    if (!_initialized) return;

    final parts = timeHHmm.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final now = DateTime.now();
    DateTime target;
    if (isDaily) {
      target = DateTime(now.year, now.month, now.day, hour, minute);
      if (skipToday || !target.isAfter(now)) {
        target = DateTime(now.year, now.month, now.day + 1, hour, minute);
      }
    } else {
      target = DateTime(year, month, day, hour, minute);
      if (!target.isAfter(now)) {
        await cancelTaskReminder(taskId); // Đã qua giờ -> không nhắc nữa
        return;
      }
    }

    final body = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : "[$category] Đến giờ thực hiện lúc $timeHHmm. Hoàn thành đúng hạn để nhận vàng & hồi máu!";

    try {
      await _plugin.zonedSchedule(
        taskId,
        "⏰ $title",
        body,
        // Thời điểm tuyệt đối (UTC) tương ứng với giờ địa phương đã chọn
        tz.TZDateTime.from(target, tz.UTC),
        _details,
        androidScheduleMode: _canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: isDaily ? DateTimeComponents.time : null,
      );
      debugPrint("Đã đặt nhắc nhở [$title] lúc $target (hàng ngày: $isDaily)");
    } catch (e) {
      debugPrint("Lỗi đặt nhắc nhở [$title]: $e");
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(taskId);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  // Thông báo hiện ngay (dùng cho nhắc nhở GPS khi đến gần địa điểm)
  Future<void> showNotification(String title, String body) async {
    if (!_initialized) return;
    final id = _instantIdBase + DateTime.now().millisecondsSinceEpoch % 100000;
    await _plugin.show(id, title, body, _details);
  }

  // Đặt lại toàn bộ nhắc nhở của 1 tài khoản (gọi khi đăng nhập).
  // Vì nhiều tài khoản có thể dùng chung 1 máy, xóa hết lịch cũ trước.
  Future<void> rescheduleAllForUser(int userId) async {
    if (!_initialized) return;
    await cancelAll();

    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final allTasks = await db.getTasks(userId);
    final todayTasks = await db.getTasksForDate(
      userId,
      now.day,
      now.month,
      now.year,
    );
    final doneTodayIds = {
      for (final t in todayTasks)
        if (t.isDaily && t.isDone && t.id != null) t.id!,
    };

    for (final t in allTasks) {
      if (t.id == null || !t.reminderEnabled) continue;
      if (!t.isDaily && t.isDone) continue;
      await scheduleTaskReminder(
        taskId: t.id!,
        title: t.title,
        category: t.category,
        timeHHmm: t.time,
        day: t.day,
        month: t.month,
        year: t.year,
        isDaily: t.isDaily,
        description: t.description,
        skipToday: doneTodayIds.contains(t.id),
      );
    }
  }
}
