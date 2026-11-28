import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/app_session.dart';
import '../core/database_helper.dart';

// Đẩy dữ liệu sang widget ngoài màn hình chính (hiện chỉ hỗ trợ Android).
class WidgetService {
  // !!! Phải TRÙNG package của file Kotlin TaskWidgetProvider.kt
  // (xem dòng "package ..." ở đầu file MainActivity.kt của bạn)
  static const String _kotlinPackage = 'com.example.task_management_app';
  static const String _providerName = 'TaskWidgetProvider';

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> _push(Map<String, String> data) async {
    for (final e in data.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(
      androidName: _providerName,
      qualifiedAndroidName: '$_kotlinPackage.$_providerName',
    );
  }

  // Lấy dữ liệu mới nhất của tài khoản đang đăng nhập rồi cập nhật widget
  static Future<void> update() async {
    if (!_supported) return;
    try {
      final user = AppSession.currentUser;
      if (user == null || user.id == null) {
        await clear();
        return;
      }

      final now = DateTime.now();
      final tasks = await DatabaseHelper.instance.getTasksForDate(
        user.id!,
        now.day,
        now.month,
        now.year,
      );
      final pending = tasks.where((t) => !t.isDone).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      String line(int i) =>
          i < pending.length ? '${pending[i].time}  ${pending[i].title}' : '';

      await _push({
        'w_logged_in': '1',
        'w_name': user.name,
        'w_streak': '${user.currentStreak}',
        'w_hp': '${user.hp}',
        'w_gold': '${user.gold}',
        'w_pending': '${pending.length}',
        'w_total': '${tasks.length}',
        'w_task1': line(0),
        'w_task2': line(1),
        'w_task3': line(2),
      });
    } catch (e) {
      debugPrint('Lỗi cập nhật widget: $e');
    }
  }

  // Gọi khi đăng xuất để widget không hiện dữ liệu của tài khoản cũ
  static Future<void> clear() async {
    if (!_supported) return;
    try {
      await _push({
        'w_logged_in': '0',
        'w_name': '',
        'w_streak': '0',
        'w_hp': '0',
        'w_gold': '0',
        'w_pending': '0',
        'w_total': '0',
        'w_task1': '',
        'w_task2': '',
        'w_task3': '',
      });
    } catch (e) {
      debugPrint('Lỗi xóa dữ liệu widget: $e');
    }
  }
}
