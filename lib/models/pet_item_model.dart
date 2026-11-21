import 'package:flutter/material.dart';

class PetItemModel {
  final String id;
  final String name;
  final String type;
  final IconData icon;
  final String? imagePath;

  PetItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.imagePath,
  });
}
