import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class PetView extends StatefulWidget {
  const PetView({super.key});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  // BIẾN GIẢ LẬP DỮ LIỆU THỰC TẾ (Để Test UI)
  int currentStreak = 12; // Số ngày chuỗi
  bool isTaskDoneToday = true; // Đã làm công việc hôm nay chưa?

  // Trạng thái trang bị
  String? equippedHat;
  String? equippedGlasses;
  String? equippedShirt;

  final List<Map<String, dynamic>> inventory = [
    {
      "id": "hat",
      "name": "Mũ Rơm",
      "type": "hat",
      "icon": Icons.face_retouching_natural,
    },
    {
      "id": "glasses",
      "name": "Kính Râm",
      "type": "glasses",
      "icon": Icons.visibility,
    },
    {
      "id": "shirt",
      "name": "Áo Choàng",
      "type": "shirt",
      "icon": Icons.dry_cleaning,
    },
  ];

  // Logic kiểm tra xem có được mặc đồ không
  bool get canEquipItems => currentStreak >= 10 && isTaskDoneToday;

  void _equipItem(Map<String, dynamic> item) {
    if (currentStreak == 0) {
      _showMsg("Pet đã cạn kiệt năng lượng! Hãy bắt đầu chuỗi mới.");
      return;
    }
    if (!isTaskDoneToday) {
      _showMsg(
        "Pet đang bị đóng băng! Hãy hoàn thành công việc hôm nay để rã đông.",
      );
      return;
    }
    if (currentStreak < 10) {
      _showMsg("Cần đạt Chuỗi 10 ngày để tiến hóa thành Lửa Lớn và mặc đồ!");
      return;
    }

    setState(() {
      if (item["type"] == "hat") {
        equippedHat = (equippedHat == item["id"]) ? null : item["id"];
      } else if (item["type"] == "glasses") {
        equippedGlasses = (equippedGlasses == item["id"]) ? null : item["id"];
      } else if (item["type"] == "shirt") {
        equippedShirt = (equippedShirt == item["id"]) ? null : item["id"];
      }
    });
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ==========================================
  // BỘ NÃO XỬ LÝ ẢNH DỰA TRÊN LOGIC CHUỖI
  // ==========================================
  String _getPetImagePath() {
    // 1. MẤT CHUỖI (Streak = 0) -> Cục lửa xám
    if (currentStreak == 0) {
      return 'assets/images/pet/pet_gray.png';
    }

    // 2. CHƯA LÀM TASK HÔM NAY -> Đóng băng
    if (!isTaskDoneToday) {
      return currentStreak >= 10
          ? 'assets/images/pet/pet_lv2_frozen.png'
          : 'assets/images/pet/pet_lv1_frozen.png';
    }

    // 3. CHUỖI NHỎ HƠN 10 -> Cấp 1 (Chưa được mặc đồ)
    if (currentStreak < 10) {
      return 'assets/images/pet/pet_lv1_base.png';
    }

    // 4. CHUỖI >= 10 VÀ ĐÃ LÀM TASK -> Cấp 2 (Có thể mặc đồ)
    bool hasHat = equippedHat != null;
    bool hasGlasses = equippedGlasses != null;
    bool hasShirt = equippedShirt != null;

    if (hasHat && hasGlasses && hasShirt)
      return 'assets/images/pet/pet_lv2_all.png';
    if (hasHat && hasGlasses)
      return 'assets/images/pet/pet_lv2_hat_glasses.png';
    if (hasHat && hasShirt) return 'assets/images/pet/pet_lv2_hat_shirt.png';
    if (hasGlasses && hasShirt)
      return 'assets/images/pet/pet_lv2_glasses_shirt.png';
    if (hasHat) return 'assets/images/pet/pet_lv2_hat.png';
    if (hasGlasses) return 'assets/images/pet/pet_lv2_glasses.png';
    if (hasShirt) return 'assets/images/pet/pet_lv2_shirt.png';

    // Cấp 2 không mặc đồ
    return 'assets/images/pet/pet_lv2_base.png';
  }

  // Lấy tên trạng thái hiển thị
  String _getPetStatusText() {
    if (currentStreak == 0) return "Trạng thái: Lụi tàn (Hãy cố gắng nhé!)";
    if (!isTaskDoneToday) return "Trạng thái: Bị đóng băng (Chưa làm task)";
    return "Trạng thái: Đang cháy rực rỡ";
  }

  String _getPetLevelText() {
    if (currentStreak == 0) return "Tro tàn";
    if (currentStreak >= 10) return "Lửa Lớn (Cấp 2)";
    return "Lửa Nhỏ (Cấp 1)";
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
          // KHU VỰC DEBUG ĐỂ BẠN TỰ TEST TRẠNG THÁI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: AppColors.card,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    currentStreak = 0;
                    equippedHat = null;
                    equippedGlasses = null;
                    equippedShirt = null;
                  }),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text(
                    "Test Xám",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {
                    currentStreak = 5;
                    equippedHat = null;
                    equippedGlasses = null;
                    equippedShirt = null;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                  ),
                  child: const Text(
                    "Test Cấp 1",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => currentStreak = 15),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text(
                    "Test Cấp 2",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => isTaskDoneToday = !isTaskDoneToday),
                  icon: Icon(
                    isTaskDoneToday ? Icons.check_circle : Icons.ac_unit,
                    color: isTaskDoneToday
                        ? Colors.green
                        : Colors.lightBlueAccent,
                  ),
                  tooltip: "Đổi trạng thái Băng/Rã băng",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // HIỂN THỊ ẢNH PET
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.asset(
                _getPetImagePath(),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.image_not_supported,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Đang chờ bạn tạo ảnh này...",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            _getPetLevelText(),
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getPetStatusText(),
            style: TextStyle(
              color: currentStreak == 0
                  ? Colors.grey
                  : (!isTaskDoneToday
                        ? Colors.lightBlueAccent
                        : Colors.greenAccent),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // TỦ ĐỒ (Khóa mờ nếu chưa đủ điều kiện)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tủ đồ của Pet",
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!canEquipItems)
                        const Icon(
                          Icons.lock_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: Opacity(
                      opacity: canEquipItems
                          ? 1.0
                          : 0.4, // Làm mờ tủ đồ nếu bị cấm
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
                              (equippedHat == item["id"] ||
                              equippedGlasses == item["id"] ||
                              equippedShirt == item["id"]);

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
