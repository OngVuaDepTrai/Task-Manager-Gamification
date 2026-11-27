class TaskModel {
  int? id;
  final int day;
  final int month;
  final int year;
  final String title;
  final String? description; // Mô tả chi tiết (không bắt buộc)
  final String time; // Định dạng "HH:mm"
  final String category;
  final bool isDaily;
  final bool isHighPriority;
  final int exp;
  final int gold;
  bool isDone;
  final String? locationName;
  final bool reminderEnabled;
  // Việc nhóm được giao: id và tên nhóm (null nếu là việc cá nhân)
  final int? groupId;
  final String? groupName;
  // Chủ sở hữu task (người đảm nhận) - đọc từ cột user_id
  final int? ownerId;

  bool get isGroupTask => groupId != null;

  TaskModel({
    this.id,
    required this.day,
    int? month,
    int? year,
    required this.title,
    this.description,
    required this.time,
    required this.category,
    this.isDaily = false,
    this.isHighPriority = false,
    this.exp = 20,
    this.gold = 10,
    this.isDone = false,
    this.locationName,
    this.reminderEnabled = true,
    this.groupId,
    this.groupName,
    this.ownerId,
  }) : month = month ?? DateTime.now().month,
       year = year ?? DateTime.now().year;

  TaskModel copyWith({
    int? id,
    int? day,
    int? month,
    int? year,
    String? title,
    String? description,
    String? time,
    String? category,
    bool? isDaily,
    bool? isHighPriority,
    int? exp,
    int? gold,
    bool? isDone,
    String? locationName,
    bool? reminderEnabled,
    int? groupId,
    String? groupName,
    int? ownerId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      day: day ?? this.day,
      month: month ?? this.month,
      year: year ?? this.year,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      category: category ?? this.category,
      isDaily: isDaily ?? this.isDaily,
      isHighPriority: isHighPriority ?? this.isHighPriority,
      exp: exp ?? this.exp,
      gold: gold ?? this.gold,
      isDone: isDone ?? this.isDone,
      locationName: locationName ?? this.locationName,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  String dateKeyFor(int d, int m, int y) {
    final dd = d.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$y-$mm-$dd';
  }

  bool isOverdue([DateTime? now]) {
    if (isDone || isDaily) return false;
    final current = now ?? DateTime.now();
    final parts = time.split(':');
    final hour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 23) : 23;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 59) : 59;
    final dueDateTime = DateTime(year, month, day, hour, minute);
    return current.isAfter(dueDateTime);
  }

  Map<String, dynamic> toMap(int userId) {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'day': day,
      'month': month,
      'year': year,
      'title': title,
      'description': description,
      'time': time,
      'category': category,
      'isDaily': isDaily ? 1 : 0,
      'isHighPriority': isHighPriority ? 1 : 0,
      'isDone': isDone ? 1 : 0,
      'exp_reward': exp,
      'gold_reward': gold,
      'locationName': locationName,
      'reminderEnabled': reminderEnabled ? 1 : 0,
      'group_id': groupId,
      'group_name': groupName,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return TaskModel(
      id: map['id'],
      day: map['day'] ?? now.day,
      month: map['month'] ?? now.month,
      year: map['year'] ?? now.year,
      title: map['title'] ?? '',
      description: map['description'],
      time: map['time'] ?? '08:00',
      category: map['category'] ?? 'Cá nhân',
      isDaily: (map['isDaily'] ?? 0) == 1,
      isHighPriority: (map['isHighPriority'] ?? 0) == 1,
      isDone: (map['isDone'] ?? 0) == 1,
      exp: map['exp_reward'] ?? 20,
      gold: map['gold_reward'] ?? 10,
      locationName: map['locationName'],
      reminderEnabled: (map['reminderEnabled'] ?? 1) == 1,
      groupId: map['group_id'],
      groupName: map['group_name'],
      ownerId: map['user_id'],
    );
  }
}
