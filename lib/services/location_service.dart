import 'package:geolocator/geolocator.dart';

import 'notification_service.dart';

class LocationService {
  static double distance(
    double lat,
    double lng,
    double targetLat,
    double targetLng,
  ) => Geolocator.distanceBetween(lat, lng, targetLat, targetLng);
  static Future<void> notifyArrival(String title, String location) =>
      NotificationService().showNotification(
        title.isEmpty ? 'Nhắc công việc' : title,
        location,
      );
}
