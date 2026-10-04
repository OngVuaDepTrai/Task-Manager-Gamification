import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class PetView extends StatefulWidget {
  const PetView({super.key});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  // Trạng thái trang bị hiện tại (3 slots: Mũ, Kính, Áo)
  String? equippedHat;
  String? equippedGlasses;
  String? equippedShirt;

  // Tủ đồ đã gỡ bỏ Giày
  final List<Map<String, dynamic>> inventory = [
    {
      "id": "hat_straw",
      "name": "Mũ Rơm",
      "type": "hat",
      "icon": Icons.face_retouching_natural,
      "image": "assets/images/pet/hat_straw.png",
    },
    {
      "id": "glasses_cool",
      "name": "Kính Râm",
      "type": "glasses",
      "icon": Icons.visibility,
      "image": "assets/images/pet/glasses_cool.png",
    },
    {
      "id": "shirt_red",
      "name": "Áo Choàng",
      "type": "shirt",
      "icon": Icons.dry_cleaning,
      "image": "assets/images/pet/shirt_red.png",
    },
  ];

  void _equipItem(Map<String, dynamic> item) {
    setState(() {
      if (item["type"] == "hat") {
        equippedHat = (equippedHat == item["image"]) ? null : item["image"];
      } else if (item["type"] == "glasses") {
        equippedGlasses = (equippedGlasses == item["image"])
            ? null
            : item["image"];
      } else if (item["type"] == "shirt") {
        equippedShirt = (equippedShirt == item["image"]) ? null : item["image"];
      }
    });
  }

  // Hàm render 1 lớp ảnh đè lên Pet, có fallback nếu chưa gắn ảnh
  Widget _buildLayer(String? imagePath) {
    if (imagePath == null) return const SizedBox.shrink();
    return Image.asset(
      imagePath,
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.image_not_supported,
        color: Colors.redAccent,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Phòng Thú Cưng',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // KHU VỰC HIỂN THỊ PET - XẾP CHỒNG THEO THỨ TỰ TỪ DƯỚI LÊN
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Layer Pet Gốc
                  Image.asset(
                    'assets/images/pet/pet_base.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 80,
                        ),
                      ),
                    ),
                  ),

                  // 2. Layer Áo
                  _buildLayer(equippedShirt),

                  // 3. Layer Kính
                  _buildLayer(equippedGlasses),

                  // 4. Layer Mũ
                  _buildLayer(equippedHat),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Lửa nhỏ (Cấp 1)",
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Trạng thái: Vui vẻ",
            style: TextStyle(color: Colors.greenAccent, fontSize: 14),
          ),
          const SizedBox(height: 30),

          // TỦ ĐỒ (INVENTORY)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tủ đồ của Pet",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                          ),
                      itemCount: inventory.length,
                      itemBuilder: (context, index) {
                        var item = inventory[index];
                        bool isEquipped =
                            (equippedHat == item["image"] ||
                            equippedGlasses == item["image"] ||
                            equippedShirt == item["image"]);

                        return GestureDetector(
                          onTap: () => _equipItem(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isEquipped
                                  ? AppColors.primary.withAlpha(40)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isEquipped
                                    ? AppColors.primary
                                    : Colors.grey.shade800,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item["icon"],
                                  color: isEquipped
                                      ? AppColors.primary
                                      : AppColors.textSub,
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item["name"],
                                  style: TextStyle(
                                    color: isEquipped
                                        ? AppColors.textMain
                                        : AppColors.textSub,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
