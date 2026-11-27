import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_session.dart';
import '../core/database_helper.dart';
import '../models/task_model.dart';

class NotificationService {
  static final _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initializing;
  Future<void> _queue = Future.value();
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static const details = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders',
      'Nhắc công việc',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _initialize() async {
    zones.initializeTimeZones();
    final name = await const MethodChannel('tasks/timezone')
        .invokeMethod<String>('local');
    tz.setLocalLocation(tz.getLocation(name!));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_task_reminder'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _run(Future<void> Function() action) {
    if (!supported) return Future.value();
    final job = _queue.then((_) async {
      try {
        await (_initializing ??= _initialize());
      } catch (_) {
        _initializing = null;
        rethrow;
      }
      await action();
    });
    _queue = job.catchError((Object _) {});
    return job;
  }

  Future<void> restore() => _run(() async {
    final id = AppSession.currentUser?.id;
    await plugin.cancelAll();
    if (id == null) return;
    final now = DateTime.now(), db = DatabaseHelper.instance;
    final tasks = await db.getTasks(id);
    final today = await db.getTasksForDate(id, now.day, now.month, now.year);
    final completed = {
      for (final t in today)
        if (t.isDone) t.id,
    };
    for (final t in tasks) {
      if (AppSession.currentUser?.id != id) return;
      await _schedule(
        t.copyWith(isDone: t.isDaily ? completed.contains(t.id) : t.isDone),
      );
    }
  });
  Future<void> syncTask(TaskModel task) => _run(() => _schedule(task));
  Future<void> _schedule(TaskModel task) async {
    final id = task.id!;
    await plugin.cancel(id: id);
    if (!task.reminderEnabled || (!task.isDaily && task.isDone)) return;
    final now = tz.TZDateTime.now(tz.local), parts = task.time.split(':');
    final h = int.parse(parts.first), m = int.parse(parts.last);
    var start = tz.TZDateTime(tz.local, task.year, task.month, task.day, h, m);
    if (task.isDaily) {
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
      if (!next.isAfter(now) || task.isDone) {
        next = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, h, m);
      }
      if (start.isBefore(next)) start = next;
    }
    if (!start.isAfter(now)) return;
    // Calendar matching ignores the start date on mobile. Use a dated reminder when today's time must be skipped.
    final todayTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      h,
      m,
    );
    final nextMatch = todayTime.isAfter(now)
        ? todayTime
        : tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, h, m);
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() == false ||
        (await ios?.checkPermissions())?.isEnabled == false) {
      throw PlatformException(
        code: 'permission_denied',
        message: 'Hãy bật quyền thông báo trong cài đặt thiết bị.',
      );
    }
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await plugin.zonedSchedule(
      id: id,
      title: task.title,
      body: '${task.category} · ${task.time}',
      scheduledDate: start,
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: task.isDaily && start == nextMatch
          ? DateTimeComponents.time
          : null,
    );
  }

  Future<void> clear() => _run(plugin.cancelAll);
  Future<void> cancelTaskReminder(int id) => _run(() => plugin.cancel(id: id));
  Future<void> showNotification(String title, String body) => _run(
    () => plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    ),
  );
}
