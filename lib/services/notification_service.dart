import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/database_helper.dart';

// Service thông báo nhắc nhở công việc (dùng flutter_local_notifications).
//
// Mỗi task có 2 thông báo do hệ điều hành lên lịch (vẫn hiện khi đã tắt app):
//  - Nhắc trước [leadMinutes] phút: "Sắp đến giờ"
//  - Nhắc đúng giờ
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

  // Nhắc trước bao nhiêu phút
  static const int leadMinutes = 5;

  // ID thông báo tức thời (GPS), đặt rất lớn để không trùng ID của task
  static const int _instantIdBase = 1000000000;

  // Mỗi task dùng 2 ID: chẵn = đúng giờ, lẻ = nhắc trước
  int _dueId(int taskId) => taskId * 2;
  int _preId(int taskId) => taskId * 2 + 1;

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

  // Cập nhật quyền "báo thức chính xác" (người dùng có thể vừa bật trong Cài đặt)
  Future<void> _refreshExactPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      _canScheduleExact =
          await android.canScheduleExactNotifications() ?? false;
    }
  }

  // Xin quyền thông báo (Android 13+ / iOS) và quyền báo thức chính xác.
  // askExactAlarm = false: chỉ kiểm tra, không mở trang Cài đặt (dùng khi tự đăng nhập)
  Future<void> requestPermissions({bool askExactAlarm = true}) async {
    if (!_initialized) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      var canExact = await android.canScheduleExactNotifications() ?? false;
      if (!canExact && askExactAlarm) {
        // Mở trang "Báo thức & lời nhắc" để người dùng cho phép
        await android.requestExactAlarmsPermission();
        canExact = await android.canScheduleExactNotifications() ?? false;
      }
      _canScheduleExact = canExact;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Đặt lịch nhắc cho 1 task (2 thông báo: trước 5 phút + đúng giờ).
  // - Task thường: nhắc 1 lần (bỏ qua phần đã qua giờ).
  // - Task hàng ngày: lặp lại mỗi ngày.
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
    await _refreshExactPermission();

    final parts = timeHHmm.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 8) : 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final now = DateTime.now();

    // Thời điểm đúng giờ
    DateTime due;
    if (isDaily) {
      due = DateTime(now.year, now.month, now.day, hour, minute);
      if (skipToday || !due.isAfter(now)) {
        due = DateTime(now.year, now.month, now.day + 1, hour, minute);
      }
    } else {
      due = DateTime(year, month, day, hour, minute);
      if (!due.isAfter(now)) {
        await cancelTaskReminder(taskId); // Đã qua giờ -> không nhắc nữa
        return;
      }
    }

    // Thời điểm nhắc trước
    DateTime pre = due.subtract(const Duration(minutes: leadMinutes));
    bool schedulePre = true;
    if (!pre.isAfter(now)) {
      if (isDaily) {
        // Hôm nay đã lỡ mốc nhắc trước -> mốc kế tiếp là ngày mai
        pre = pre.add(const Duration(days: 1));
      } else {
        schedulePre = false; // Task thường: chỉ còn nhắc đúng giờ
      }
    }

    final dueBody = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : "[$category] Đến giờ thực hiện lúc $timeHHmm. Hoàn thành đúng hạn để nhận vàng & hồi máu!";
    final preBody =
        "[$category] Còn $leadMinutes phút nữa đến giờ thực hiện (lúc $timeHHmm). Chuẩn bị nhé!";

    final mode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final match = isDaily ? DateTimeComponents.time : null;

    try {
      // Thông báo đúng giờ
      await _plugin.zonedSchedule(
        _dueId(taskId),
        "⏰ $title",
        dueBody,
        tz.TZDateTime.from(due, tz.UTC),
        _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: match,
      );

      // Thông báo nhắc trước
      if (schedulePre) {
        await _plugin.zonedSchedule(
          _preId(taskId),
          "⏳ Sắp đến giờ: $title",
          preBody,
          tz.TZDateTime.from(pre, tz.UTC),
          _details,
          androidScheduleMode: mode,
          matchDateTimeComponents: match,
        );
      } else {
        await _plugin.cancel(_preId(taskId));
      }

      debugPrint(
        "Đã đặt nhắc nhở [$title]: trước=${schedulePre ? pre : 'không'}, "
        "đúng giờ=$due (hàng ngày: $isDaily, chính xác: $_canScheduleExact)",
      );
    } catch (e) {
      debugPrint("Lỗi đặt nhắc nhở [$title]: $e");
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(_dueId(taskId));
    await _plugin.cancel(_preId(taskId));
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

  // Đặt lại toàn bộ nhắc nhở của 1 tài khoản (gọi khi đăng nhập / mở app).
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

  // ====================== VIỆC NHÓM MỚI (REALTIME) ======================
  // Tăng lên mỗi khi có việc nhóm mới -> Trang chủ lắng nghe để tải lại danh sách
  static final ValueNotifier<int> groupTaskArrived = ValueNotifier<int>(0);

  // Bắt đầu nghe việc nhóm mới được giao: báo ngay + đặt lịch nhắc.
  // Gọi sau khi đăng nhập / khôi phục phiên.
  void startGroupTaskListener(int userId) {
    DatabaseHelper.instance.listenAssignedTasks(userId, (task) async {
      try {
        await showNotification(
          '📋 Việc nhóm mới: ${task.title}',
          'Nhóm "${task.groupName ?? ''}" vừa giao cho bạn, hạn ${task.time} '
              '${task.day}/${task.month}/${task.year}',
        );
        if (task.id != null && task.reminderEnabled) {
          await scheduleTaskReminder(
            taskId: task.id!,
            title: task.title,
            category: task.category,
            timeHHmm: task.time,
            day: task.day,
            month: task.month,
            year: task.year,
            isDaily: false,
            description: task.description,
          );
        }
      } catch (e) {
        debugPrint('Xử lý việc nhóm mới lỗi: $e');
      }
      groupTaskArrived.value++;
    });
  }

  // Gọi khi đăng xuất
  void stopGroupTaskListener() {
    DatabaseHelper.instance.stopListeningTasks();
  }
}
