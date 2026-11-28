class NotificationModel {
  final int id;
  final String type; // 'task_assigned'
  final String message;
  final String createdAt; // ISO8601
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      type: map['type'] ?? 'task_assigned',
      message: map['message'] ?? '',
      createdAt: map['created_at'] ?? '',
      isRead: (map['is_read'] ?? 0) == 1,
    );
  }
}
