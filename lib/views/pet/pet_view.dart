import 'package:provider/provider.dart';

import '../../view_models/gamification_view_model.dart';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../models/pet_model.dart';
import '../../models/pet_item_model.dart';

class PetView extends StatefulWidget {
  const PetView({super.key});

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView> {
  GamificationViewModel get game => context.read<GamificationViewModel>();
  int get currentStreak => AppSession.currentUser!.currentStreak;
  bool get isTaskDoneToday => game.activeToday;
  // Các vị trí trang bị
  final List<PetItemModel> inventory = [
    PetItemModel(
      id: "hat_straw",
      name: "Mũ Rơm",
      type: "hat",
      icon: Icons.face_retouching_natural,
    ),
    PetItemModel(
      id: "glasses_cool",
      name: "Kính Râm",
      type: "glasses",
      icon: Icons.visibility,
    ),
    PetItemModel(
      id: "shirt_red",
      name: "Áo Choàng",
      type: "shirt",
      icon: Icons.dry_cleaning,
    ),
  ];

  // Điều kiện để được mặc đồ: Chuỗi >= 10 ngày & Đã hoàn thành task hôm nay
  bool get canEquipItems => currentStreak >= 10 && isTaskDoneToday;

  void _equipItem(PetItemModel item) {
    if (currentStreak == 0) {
      _showMsg("Pet chưa được thắp sáng! Hãy hoàn thành công việc đầu tiên.");
      return;
    }
    if (!isTaskDoneToday) {
      _showMsg(
        "Pet đang bị đóng băng! Hãy hoàn thành ít nhất 1 công việc hôm nay để rã đông.",
      );
      return;
    }
    if (currentStreak < 10) {
      _showMsg("Cần đạt Chuỗi 10 ngày để tiến hóa thành Lửa Lớn và mặc đồ!");
      return;
    }

    if (!game.inventory.containsKey(item.type)) {
      _showMsg('Hãy mua vật phẩm tại cửa hàng.');
      return;
    }
    game.equip(item.type, game.inventory[item.type] != true);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _getPetImagePath() =>
      PetModel.asset(currentStreak, isTaskDoneToday, game.inventory);
  String _getPetStatusText() {
    if (currentStreak == 0) return "Trạng thái: Chưa được thắp sáng";
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
    context.watch<GamificationViewModel>();
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
          const SizedBox(
            height: 40,
          ), // Đã loại bỏ hoàn toàn các nút Test Button
          // Hiển thị ảnh Pet theo trạng thái
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Image.asset(
                _getPetImagePath(),
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
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
                  );
                },
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
          const SizedBox(height: 30),

          // Tủ đồ (Inventory)
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
                      // Hiển thị ổ khóa nếu chưa đủ điều kiện
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
                      // Làm mờ tủ đồ nếu bị khóa
                      opacity: canEquipItems ? 1.0 : 0.4,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                            ),
                        itemCount: inventory.length,
                        itemBuilder: (context, index) {
                          final PetItemModel item = inventory[index];
                          final bool isEquipped =
                              game.inventory[item.type] == true;

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
                                    item.icon,
                                    color: isEquipped
                                        ? AppColors.primary
                                        : AppColors.textSub,
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    game.inventory.containsKey(item.type)
                                        ? item.name
                                        : '${item.name} 🔒',
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
