import 'package:flutter/foundation.dart';

// Service chuyên xử lý GPS và Geofencing (Hàng rào địa lý)
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<void> initLocationService() async {
    debugPrint("Đã khởi tạo dịch vụ Location & GPS.");
  }

  // Đăng ký theo dõi vị trí nền (Background Location)
  Future<void> startGeofencingTracking(
    double targetLat,
    double targetLng,
    double radiusInMeters,
  ) async {
    debugPrint(
      "Bắt đầu theo dõi tọa độ: $targetLat, $targetLng trong vòng bán kính $radiusInMeters m.",
    );
    // Tuần 10 sẽ tích hợp logic chạy ngầm vào đây
  }

  // Hàm tính toán khoảng cách
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    // Thuật toán Haversine hoặc dùng Geolocator
    return 0.0;
  }
}
