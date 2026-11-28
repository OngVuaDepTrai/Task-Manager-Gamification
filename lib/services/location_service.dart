import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_session.dart';
import '../core/database_helper.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

// Một điểm cần theo dõi (lấy từ task có đặt vị trí)
class _LocationTarget {
  final int taskId;
  final String title;
  final String placeName;
  final double lat;
  final double lng;
  final int radius;

  _LocationTarget(TaskModel t)
    : taskId = t.id!,
      title = t.title,
      placeName = t.locationName ?? 'địa điểm đã hẹn',
      lat = t.locationLat!,
      lng = t.locationLng!,
      radius = t.locationRadius;
}

// Service nhắc nhở theo vị trí (Geofencing).
//
// - Theo dõi vị trí ở cấp toàn app (không phụ thuộc màn hình nào đang mở).
// - Trên Android chạy dưới dạng Foreground Service của geolocator (có 1 thông
//   báo cố định "Đang theo dõi vị trí"), nên app ở nền vẫn nhận được vị trí.
// - Khi đi VÀO vùng bán kính của 1 task chưa hoàn thành -> bắn thông báo.
//   Mỗi task chỉ nhắc lại sau khi đã ra khỏi vùng, và tối đa 1 lần / giờ.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _sub;
  List<_LocationTarget> _targets = [];
  final Set<int> _inside = {}; // Các task mà người dùng đang ở trong vùng
  final Map<int, DateTime> _lastNotified = {};

  static const Duration _cooldown = Duration(hours: 1);
  // Phải ra xa thêm 50m mới tính là "đã rời vùng" (tránh nhắc liên tục khi đứng sát mép)
  static const double _exitMargin = 50;

  bool get isMonitoring => _sub != null;

  // Kiểm tra / xin quyền vị trí. request = false: chỉ kiểm tra, không hỏi.
  // Trả về null nếu OK, ngược lại trả về lý do để hiển thị.
  Future<String?> ensurePermission({bool request = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Vui lòng bật GPS (Vị trí) trên điện thoại.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Ứng dụng chưa được cấp quyền vị trí.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt.';
    }
    return null;
  }

  Future<Position?> getCurrentPosition() async {
    if (await ensurePermission() != null) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('Lấy vị trí hiện tại lỗi: $e');
      return await Geolocator.getLastKnownPosition();
    }
  }

  // Tải lại danh sách task có vị trí của tài khoản đang đăng nhập
  // và bật/tắt theo dõi cho phù hợp. Gọi sau khi đăng nhập, sau khi
  // thêm/sửa/xóa/hoàn thành task.
  Future<void> refresh() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) {
      await stop();
      return;
    }
    try {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();
      final results = await Future.wait([
        db.getTasks(user.id!),
        db.getTasksForDate(user.id!, now.day, now.month, now.year),
      ]);
      final all = results[0];
      final doneDailyToday = {
        for (final t in results[1])
          if (t.isDaily && t.isDone && t.id != null) t.id!,
      };

      final targets = all
          .where(
            (t) =>
                t.id != null &&
                t.hasLocation &&
                t.reminderEnabled &&
                !(t.isDaily ? doneDailyToday.contains(t.id) : t.isDone),
          )
          .map(_LocationTarget.new)
          .toList();

      _targets = targets;
      final ids = targets.map((t) => t.taskId).toSet();
      _inside.removeWhere((id) => !ids.contains(id));

      if (targets.isEmpty) {
        await _stopStream();
        return;
      }
      // Chỉ kiểm tra quyền, không bật hộp thoại xin quyền ở đây
      if (await ensurePermission(request: false) != null) {
        await _stopStream();
        return;
      }
      _startStream();
    } catch (e) {
      debugPrint('LocationService.refresh lỗi: $e');
    }
  }

  LocationSettings _settings() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        intervalDuration: const Duration(seconds: 20),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Nhắc nhở theo vị trí đang bật',
          notificationText:
              'Bạn sẽ được nhắc khi đến gần địa điểm đã hẹn trong công việc.',
          setOngoing: true,
        ),
      );
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
  }

  void _startStream() {
    if (_sub != null) return;
    _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      _onPosition,
      onError: (e) => debugPrint('Theo dõi vị trí lỗi: $e'),
    );
    debugPrint('Bắt đầu theo dõi ${_targets.length} địa điểm nhắc nhở.');
  }

  void _onPosition(Position p) {
    final now = DateTime.now();
    for (final t in _targets) {
      final d = calculateDistance(p.latitude, p.longitude, t.lat, t.lng);
      if (d <= t.radius) {
        if (_inside.add(t.taskId)) {
          final last = _lastNotified[t.taskId];
          if (last == null || now.difference(last) >= _cooldown) {
            _lastNotified[t.taskId] = now;
            NotificationService().showNotification(
              '📍 Bạn đang ở gần ${t.placeName}',
              'Đến lúc làm: ${t.title} (cách ${d.round()} m)',
            );
          }
        }
      } else if (d > t.radius + _exitMargin) {
        _inside.remove(t.taskId);
      }
    }
  }

  Future<void> _stopStream() async {
    await _sub?.cancel();
    _sub = null;
  }

  // Gọi khi đăng xuất
  Future<void> stop() async {
    await _stopStream();
    _targets = [];
    _inside.clear();
    _lastNotified.clear();
  }

  // Khoảng cách (mét) giữa 2 tọa độ
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
