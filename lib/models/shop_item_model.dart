import 'package:flutter/material.dart';

class ShopItemModel {
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final String category;

  ShopItemModel({
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.category,
  });
}
