import 'package:flutter/material.dart';

class ShopItemModel {
  static final List<ShopItemModel> catalog = [
    ShopItemModel(
      name: "Uống trà sữa",
      description: "Tự thưởng cho bản thân một ly trà sữa.",
      price: 100,
      icon: Icons.local_cafe,
      category: "Cá nhân",
    ),
    ShopItemModel(
      name: "Chơi game 1 giờ",
      description: "Cho phép bản thân thư giãn.",
      price: 150,
      icon: Icons.sports_esports,
      category: "Cá nhân",
    ),
    ShopItemModel(
      slot: 'freeze',
      name: "Khiên bảo vệ chuỗi",
      description: "Bảo vệ chuỗi khi bạn bỏ lỡ một ngày.",
      price: 120,
      icon: Icons.shield_outlined,
      category: "Vật phẩm",
    ),
    ShopItemModel(
      slot: 'hat',
      name: "Mũ Rơm",
      description: "Trang bị cho Pet của bạn phong cách hải tặc.",
      price: 200,
      icon: Icons.face_retouching_natural,
      category: "Đồ Pet",
    ),
    ShopItemModel(
      slot: 'glasses',
      name: "Kính Râm Cool",
      description: "Ngầu hơn mỗi ngày.",
      price: 150,
      icon: Icons.visibility,
      category: "Đồ Pet",
    ),
    ShopItemModel(
      slot: 'shirt',
      name: "Áo Choàng Đỏ",
      description: "Pet siêu nhân.",
      price: 300,
      icon: Icons.dry_cleaning,
      category: "Đồ Pet",
    ),
  ];

  final int? id;
  final String? slot;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final String category;

  ShopItemModel({
    this.id,
    this.slot,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.category,
  });
}
