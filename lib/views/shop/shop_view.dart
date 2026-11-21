import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../../core/app_colors.dart';
import '../../models/shop_item_model.dart';
import '../../widgets/reward_card_widget.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});
  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  late ConfettiController _confettiController;
  int currentGold = 350;
  String selectedCategory = "Cá nhân";
  final List<String> categories = ["Cá nhân", "Vật phẩm", "Đồ Pet"];

  final List<ShopItemModel> rewards = [
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
      name: "Khiên bảo vệ chuỗi",
      description: "Bảo vệ chuỗi khi bạn bỏ lỡ một ngày.",
      price: 120,
      icon: Icons.shield_outlined,
      category: "Vật phẩm",
    ),
    ShopItemModel(
      name: "Mũ Rơm",
      description: "Trang bị cho Pet của bạn phong cách hải tặc.",
      price: 200,
      icon: Icons.face_retouching_natural,
      category: "Đồ Pet",
    ),
    ShopItemModel(
      name: "Kính Râm Cool",
      description: "Ngầu hơn mỗi ngày.",
      price: 150,
      icon: Icons.visibility,
      category: "Đồ Pet",
    ),
    ShopItemModel(
      name: "Áo Choàng Đỏ",
      description: "Pet siêu nhân.",
      price: 300,
      icon: Icons.dry_cleaning,
      category: "Đồ Pet",
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo controller cho hiệu ứng tung hoa
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<ShopItemModel> filteredRewards = rewards
        .where((r) => r.category == selectedCategory)
        .toList();

    // Dùng Stack để đè lớp hiệu ứng tung hoa lên trên cùng giao diện
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: const Text(
              "Cửa hàng",
              style: TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoldCard(),
                const SizedBox(height: 20),
                _buildCategoryFilter(),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredRewards.length,
                    itemBuilder: (context, index) {
                      return RewardCardWidget(
                        reward: filteredRewards[index],
                        currentGold: currentGold,
                        onBuy: () => _buyReward(filteredRewards[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: selectedCategory == "Cá nhân"
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  onPressed: () {},
                  child: const Icon(Icons.add, color: Colors.black, size: 28),
                )
              : null,
        ),

        // Lớp phủ Confetti để tung hoa
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality:
                BlastDirectionality.explosive, // Tung ra mọi hướng
            emissionFrequency: 0.05,
            numberOfParticles: 25,
            maxBlastForce: 100,
            minBlastForce: 80,
            gravity: 0.3,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withAlpha(90)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withAlpha(30),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: AppColors.gold,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Số dư của bạn",
                  style: TextStyle(color: AppColors.textSub, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "$currentGold Vàng",
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = categories[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _buyReward(ShopItemModel reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xác nhận",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          "Dùng ${reward.price} Vàng để mua '${reward.name}'?",
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              setState(() => currentGold -= reward.price);
              Navigator.pop(context); // Đóng Dialog

              // Kích hoạt hiệu ứng tung hoa
              _confettiController.play();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đổi thưởng thành công! 🎉")),
              );
            },
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
