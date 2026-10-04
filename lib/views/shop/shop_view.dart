import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});
  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  int currentGold = 350;
  String selectedCategory = "Cá nhân";

  final List<String> categories = ["Cá nhân", "Vật phẩm", "Đồ Pet"];

  final List<Map<String, dynamic>> rewards = [
    {
      "name": "Uống trà sữa",
      "description": "Tự thưởng cho bản thân một ly trà sữa.",
      "price": 100,
      "icon": Icons.local_cafe,
      "category": "Cá nhân",
    },
    {
      "name": "Chơi game 1 giờ",
      "description": "Cho phép bản thân thư giãn.",
      "price": 150,
      "icon": Icons.sports_esports,
      "category": "Cá nhân",
    },
    {
      "name": "Khiên bảo vệ chuỗi",
      "description": "Bảo vệ chuỗi khi bạn bỏ lỡ một ngày.",
      "price": 120,
      "icon": Icons.shield_outlined,
      "category": "Vật phẩm",
    },

    {
      "name": "Mũ Rơm",
      "description": "Trang bị cho Pet của bạn phong cách hải tặc.",
      "price": 200,
      "icon": Icons.face_retouching_natural,
      "category": "Đồ Pet",
    },
    {
      "name": "Kính Râm Cool",
      "description": "Ngầu hơn mỗi ngày.",
      "price": 150,
      "icon": Icons.visibility,
      "category": "Đồ Pet",
    },
    {
      "name": "Áo Choàng Đỏ",
      "description": "Pet siêu nhân.",
      "price": 300,
      "icon": Icons.dry_cleaning,
      "category": "Đồ Pet",
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRewards = rewards
        .where((r) => r["category"] == selectedCategory)
        .toList();

    return Scaffold(
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
                itemBuilder: (context, index) =>
                    _buildRewardCard(filteredRewards[index]),
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

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    bool canBuy = currentGold >= reward["price"];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[850]!),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(reward["icon"], color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward["name"],
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reward["description"],
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: AppColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${reward["price"]}",
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canBuy
                    ? AppColors.primary
                    : Colors.grey.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: canBuy ? () => _buyReward(reward) : null,
              child: Text(
                canBuy ? "Mua" : "Thiếu vàng",
                style: TextStyle(
                  color: canBuy ? Colors.black : AppColors.textSub,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _buyReward(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xác nhận",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          "Dùng ${reward["price"]} Vàng để mua \"${reward["name"]}\"?",
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
              setState(() => currentGold -= reward["price"] as int);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Thành công! 🎉")));
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
