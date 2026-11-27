import 'package:flutter/material.dart';

class AppColors {
  static const List<IconData> avatarIcons = [
    Icons.sentiment_satisfied_alt,
    Icons.pets,
    Icons.rocket_launch,
    Icons.sports_esports,
    Icons.music_note,
    Icons.local_fire_department,
    Icons.face,
    Icons.star,
  ];

  static IconData avatarIcon(String path) => avatarIcons.firstWhere(
    (icon) => icon.codePoint == int.tryParse(path.substring(5)),
    orElse: () => Icons.person,
  );
  // Tông màu tối chủ đạo
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);

  // Màu nhấn (Điểm xuyết cho nút bấm, thanh EXP)
  static const Color primary = Color(0xFFBB86FC);
  static const Color hpRed = Color(0xFFCF6679);
  static const Color gold = Color(0xFFFFD700);

  // Màu chữ
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFFAAAAAA);
}
