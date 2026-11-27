import '../core/game_rules.dart';

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

  // Máu hiện tại (tối đa GameRules.maxHp). Về 0 thì mất chuỗi.
  final int hp;
  // Số khiên đang giữ (tối đa GameRules.maxShields)
  final int shields;
  // Ngày gần nhất đã được xét thưởng/phạt, định dạng yyyy-MM-dd
  final String? lastCheckedDate;

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
    this.hp = GameRules.maxHp,
    this.shields = 0,
    this.lastCheckedDate,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    int? exp,
    int? gold,
    int? currentStreak,
    int? longestStreak,
    String? avatarPath,
    int? hp,
    int? shields,
    String? lastCheckedDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      exp: exp ?? this.exp,
      gold: gold ?? this.gold,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      avatarPath: avatarPath ?? this.avatarPath,
      hp: hp ?? this.hp,
      shields: shields ?? this.shields,
      lastCheckedDate: lastCheckedDate ?? this.lastCheckedDate,
    );
  }

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
      'hp': hp,
      'shields': shields,
      'lastCheckedDate': lastCheckedDate,
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
      hp: map['hp'] ?? GameRules.maxHp,
      shields: map['shields'] ?? 0,
      lastCheckedDate: map['lastCheckedDate'],
    );
  }
}
