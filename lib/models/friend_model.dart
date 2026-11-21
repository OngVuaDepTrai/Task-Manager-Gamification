class FriendModel {
  final int? id;
  final int userId;
  final int friendUserId;
  final String name;
  final String email;
  final String status; // 'accepted' | 'pending'
  final int currentStreak;

  FriendModel({
    this.id,
    required this.userId,
    required this.friendUserId,
    required this.name,
    required this.email,
    this.status = 'accepted',
    this.currentStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'friend_user_id': friendUserId,
      'status': status,
    };
  }

  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      id: map['id'],
      userId: map['user_id'] ?? 0,
      friendUserId: map['friend_user_id'] ?? 0,
      name: map['name'] ?? 'Người dùng',
      email: map['email'] ?? '',
      status: map['status'] ?? 'accepted',
      currentStreak: map['currentStreak'] ?? 0,
    );
  }
}
