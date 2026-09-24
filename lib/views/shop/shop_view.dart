import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  int currentGold = 350;
  String selectedCategory = "Tất cả";

  final List<String> categories = [
    "Tất cả",
    "Cá nhân",
    "Vật phẩm",
  ];

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
      "description": "Cho phép bản thân thư giãn và chơi game 1 giờ.",
      "price": 150,
      "icon": Icons.sports_esports,
      "category": "Cá nhân",
    },
    {
      "name": "Xem một bộ phim",
      "description": "Tạm nghỉ và thưởng thức một bộ phim yêu thích.",
      "price": 200,
      "icon": Icons.movie_outlined,
      "category": "Cá nhân",
    },
    {
      "name": "Ngủ nướng",
      "description": "Cho phép bản thân ngủ thêm vào ngày nghỉ.",
      "price": 250,
      "icon": Icons.bedtime_outlined,
      "category": "Cá nhân",
    },
    {
      "name": "Khiên bảo vệ chuỗi",
      "description": "Bảo vệ chuỗi khi bạn bỏ lỡ một ngày.",
      "price": 120,
      "icon": Icons.shield_outlined,
      "category": "Vật phẩm",
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredRewards =
        selectedCategory == "Tất cả"
        ? rewards
        : rewards
              .where(
                (reward) => reward["category"] == selectedCategory,
              )
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    "Phần thưởng",
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${filteredRewards.length} mục",
                    style: const TextStyle(
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                itemCount: filteredRewards.length,
                itemBuilder: (context, index) {
                  return _buildRewardCard(
                    filteredRewards[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _showCreateRewardDialog,
        child: const Icon(
          Icons.add,
          color: Colors.black,
          size: 28,
        ),
      ),
    );
  }

  // =========================
  // SỐ VÀNG
  // =========================
  Widget _buildGoldCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withAlpha(90),
        ),
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
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 14,
                  ),
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

          const Icon(
            Icons.auto_awesome,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  // =========================
  // FILTER
  // =========================
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected =
              selectedCategory == categories[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = categories[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected
                      ? Colors.black
                      : AppColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================
  // CARD PHẦN THƯỞNG
  // =========================
  Widget _buildRewardCard(
    Map<String, dynamic> reward,
  ) {
    bool canBuy = currentGold >= reward["price"];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[850]!,
        ),
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
            child: Icon(
              reward["icon"],
              color: AppColors.primary,
              size: 30,
            ),
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
              onPressed: canBuy
                  ? () => _buyReward(reward)
                  : null,
              child: Text(
                canBuy ? "Đổi" : "Thiếu vàng",
                style: TextStyle(
                  color: canBuy
                      ? Colors.black
                      : AppColors.textSub,
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

  // =========================
  // MUA / ĐỔI PHẦN THƯỞNG
  // =========================
  void _buyReward(
    Map<String, dynamic> reward,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            "Xác nhận đổi thưởng",
            style: TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Bạn có muốn dùng ${reward["price"]} Vàng để đổi \"${reward["name"]}\" không?",
            style: const TextStyle(
              color: AppColors.textSub,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Hủy",
                style: TextStyle(
                  color: AppColors.textSub,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  currentGold -= reward["price"] as int;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Đổi ${reward["name"]} thành công! 🎉",
                    ),
                  ),
                );
              },
              child: const Text(
                "Xác nhận",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // TẠO PHẦN THƯỞNG MỚI
  // =========================
  void _showCreateRewardDialog() {
    final TextEditingController nameController =
        TextEditingController();

    final TextEditingController priceController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            "Tạo phần thưởng",
            style: TextStyle(
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(
                  color: AppColors.textMain,
                ),
                decoration: const InputDecoration(
                  labelText: "Tên phần thưởng",
                  labelStyle: TextStyle(
                    color: AppColors.textSub,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.textSub,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.textMain,
                ),
                decoration: const InputDecoration(
                  labelText: "Giá Vàng",
                  labelStyle: TextStyle(
                    color: AppColors.textSub,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.textSub,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Hủy",
                style: TextStyle(
                  color: AppColors.textSub,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                String name = nameController.text.trim();
                int? price = int.tryParse(
                  priceController.text.trim(),
                );

                if (name.isEmpty ||
                    price == null ||
                    price <= 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Vui lòng nhập tên và giá hợp lệ!",
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  rewards.add({
                    "name": name,
                    "description":
                        "Phần thưởng do bạn tự tạo.",
                    "price": price,
                    "icon": Icons.card_giftcard,
                    "category": "Cá nhân",
                  });
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Đã thêm phần thưởng mới!",
                    ),
                  ),
                );
              },
              child: const Text(
                "Thêm",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}