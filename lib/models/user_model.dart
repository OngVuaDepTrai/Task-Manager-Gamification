class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final int exp;
  final int gold;
  final int currentStreak;
  final int longestStreak;
  final String? avatarPath;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.exp = 0,
    this.gold = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.avatarPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'exp': exp,
      'gold': gold,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'avatarPath': avatarPath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      exp: map['exp'] ?? 0,
      gold: map['gold'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      avatarPath: map['avatarPath'],
    );
  }
}
