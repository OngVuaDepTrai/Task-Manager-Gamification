import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../core/game_rules.dart';
import '../../models/shop_item_model.dart';
import '../../view_models/gamification_view_model.dart';
import '../../widgets/reward_card_widget.dart';

// Cửa hàng chỉ gồm 2 loại:
// 1. Khiên bảo vệ chuỗi (giá cao, giữ tối đa 2 cái) -> chống lười biếng
// 2. Phần thưởng tự đặt (giá cố định 20 vàng ~ 2 nhắc nhở) -> tự thưởng nghỉ ngơi
//    Số phần thưởng được tạo phụ thuộc cấp độ: cứ mỗi 5 cấp mở thêm 1 ô.
class ShopView extends StatefulWidget {
  const ShopView({super.key});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  late ConfettiController _confettiController;
  String selectedCategory = "Tự thưởng";
  final List<String> categories = ["Tự thưởng", "Vật phẩm"];

  List<Map<String, dynamic>> _customRewards = [];

  final ShopItemModel _shieldItem = ShopItemModel(
    name: "Khiên bảo vệ chuỗi",
    description:
        "Tự động dùng vào ngày có nhắc nhở mà bạn không hoàn thành việc nào: "
        "không bị trừ máu. Giữ tối đa ${GameRules.maxShields} khiên.",
    price: GameRules.shieldPrice,
    icon: Icons.shield_outlined,
    category: "Vật phẩm",
  );

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadCustomRewards();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomRewards() async {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;
    final list = await DatabaseHelper.instance.getCustomRewards(user.id!);
    if (!mounted) return;
    setState(() => _customRewards = list);
  }

  // ---------------- Ô PHẦN THƯỞNG THEO CẤP ----------------
  int get _level => GameRules.levelFromExp(AppSession.currentUser?.exp ?? 0);
  int get _slots => GameRules.rewardSlotsForLevel(_level);
  bool get _canAddReward => _customRewards.length < _slots;

  String _lockedMessage() {
    final nextLevel = GameRules.nextRewardSlotLevel(_level);
    final expNeeded =
        GameRules.expForLevel(nextLevel) - (AppSession.currentUser?.exp ?? 0);
    if (_slots == 0) {
      return "Đạt Lv. $nextLevel để mở ô phần thưởng đầu tiên (còn $expNeeded EXP).";
    }
    return "Đã dùng hết $_slots ô. Đạt Lv. $nextLevel để mở thêm 1 ô "
        "(còn $expNeeded EXP), hoặc xóa bớt phần thưởng cũ.";
  }

  void _onAddRewardPressed() {
    if (!_canAddReward) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_lockedMessage())));
      return;
    }
    _openAddRewardDialog();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild khi vàng / khiên / EXP thay đổi
    context.watch<GamificationViewModel>();
    final user = AppSession.currentUser;
    final int gold = user?.gold ?? 0;
    final int shields = user?.shields ?? 0;

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
                _buildGoldCard(gold),
                const SizedBox(height: 20),
                _buildCategoryFilter(),
                const SizedBox(height: 18),
                Expanded(
                  child: selectedCategory == "Vật phẩm"
                      ? _buildItemList(gold, shields)
                      : _buildCustomRewardTab(gold),
                ),
              ],
            ),
          ),
          floatingActionButton: selectedCategory == "Tự thưởng"
              ? FloatingActionButton(
                  backgroundColor: _canAddReward
                      ? AppColors.primary
                      : Colors.grey.shade800,
                  onPressed: _onAddRewardPressed,
                  child: Icon(
                    _canAddReward ? Icons.add : Icons.lock_outline,
                    color: _canAddReward ? Colors.black : AppColors.textSub,
                    size: 28,
                  ),
                )
              : null,
        ),

        // Lớp phủ Confetti để tung hoa
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
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

  // ---------------- VẬT PHẨM (KHIÊN) ----------------
  Widget _buildItemList(int gold, int shields) {
    final bool isFull = shields >= GameRules.maxShields;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        RewardCardWidget(
          reward: _shieldItem,
          currentGold: gold,
          blockedLabel: isFull ? "Đã đủ" : null,
          onBuy: () => _confirm(
            "Dùng ${GameRules.shieldPrice} Vàng để mua 1 khiên bảo vệ chuỗi?",
            () => context.read<GamificationViewModel>().buyShield(),
            "Đã mua khiên! 🛡️",
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Đang giữ: $shields/${GameRules.maxShields} khiên",
          style: const TextStyle(color: AppColors.textSub, fontSize: 13),
        ),
      ],
    );
  }

  // ---------------- PHẦN THƯỞNG TỰ ĐẶT ----------------
  Widget _buildCustomRewardTab(int gold) {
    return Column(
      children: [
        _buildSlotInfoCard(),
        const SizedBox(height: 12),
        Expanded(child: _buildCustomRewardList(gold)),
      ],
    );
  }

  // Thẻ hiển thị số ô đã dùng / đã mở và tiến độ tới ô tiếp theo
  Widget _buildSlotInfoCard() {
    final int exp = AppSession.currentUser?.exp ?? 0;
    final int level = _level;
    final int slots = _slots;
    final int used = _customRewards.length;
    final int nextLevel = GameRules.nextRewardSlotLevel(level);
    final int prevLevel = nextLevel - GameRules.levelsPerRewardSlot;
    final int fromExp = GameRules.expForLevel(prevLevel < 1 ? 1 : prevLevel);
    final int toExp = GameRules.expForLevel(nextLevel);
    final double progress = toExp == fromExp
        ? 1
        : ((exp - fromExp) / (toExp - fromExp)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Ô phần thưởng: $used/$slots",
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                "Lv. $level",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Ô tiếp theo mở ở Lv. $nextLevel "
            "(còn ${toExp - exp} EXP) · Mỗi ${GameRules.levelsPerRewardSlot} cấp +1 ô",
            style: const TextStyle(color: AppColors.textSub, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRewardList(int gold) {
    if (_customRewards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _canAddReward
                ? "Chưa có phần thưởng nào.\nBấm + để thêm hoạt động giải trí bạn muốn tự thưởng "
                      "(VD: uống trà sữa, xem 1 tập phim...).\n\n"
                      "Mỗi phần thưởng giá ${GameRules.customRewardPrice} Vàng ~ hoàn thành 2 nhắc nhở."
                : "🔒 ${_lockedMessage()}\n\n"
                      "Hoàn thành nhắc nhở để nhận EXP và lên cấp nhé!",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSub, height: 1.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: _customRewards.length,
      itemBuilder: (_, index) {
        final row = _customRewards[index];
        final item = ShopItemModel(
          name: row['name'] as String,
          description: (row['description'] as String?)?.isNotEmpty == true
              ? row['description'] as String
              : "Phần thưởng tự đặt · Nhấn giữ để xóa",
          price: GameRules.customRewardPrice,
          icon: Icons.celebration_outlined,
          category: "Tự thưởng",
        );
        return RewardCardWidget(
          reward: item,
          currentGold: gold,
          buyLabel: "Đổi",
          onLongPress: () => _deleteReward(row['id'] as int, item.name),
          onBuy: () => _confirm(
            "Dùng ${GameRules.customRewardPrice} Vàng để tự thưởng '${item.name}'?",
            () => context.read<GamificationViewModel>().redeemCustomReward(),
            "Tận hưởng nhé, bạn xứng đáng! 🎉",
          ),
        );
      },
    );
  }

  void _openAddRewardDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Thêm phần thưởng",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(
                hintText: "Tên hoạt động (VD: Xem 1 tập phim)",
                hintStyle: TextStyle(color: AppColors.textSub),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              style: const TextStyle(color: AppColors.textMain),
              decoration: const InputDecoration(
                hintText: "Mô tả (không bắt buộc)",
                hintStyle: TextStyle(color: AppColors.textSub),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Giá cố định: ${GameRules.customRewardPrice} Vàng · "
              "Ô còn trống: ${_slots - _customRewards.length}",
              style: const TextStyle(color: AppColors.gold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = nameController.text.trim();
              final user = AppSession.currentUser;
              if (name.isEmpty || user == null || user.id == null) return;

              // Kiểm tra lại số ô ngay trước khi lưu (tránh bấm 2 lần)
              final current = await DatabaseHelper.instance.getCustomRewards(
                user.id!,
              );
              if (current.length >= _slots) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(_lockedMessage())));
                _loadCustomRewards();
                return;
              }

              await DatabaseHelper.instance.insertCustomReward(
                user.id!,
                name,
                descController.text,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _loadCustomRewards();
            },
            child: const Text("Thêm", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _deleteReward(int rewardId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xóa phần thưởng",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          "Xóa '$name' khỏi danh sách tự thưởng? Ô này sẽ trống để thêm phần thưởng khác.",
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hpRed),
            onPressed: () async {
              final user = AppSession.currentUser;
              if (user?.id != null) {
                await DatabaseHelper.instance.deleteCustomReward(
                  rewardId,
                  user!.id!,
                );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _loadCustomRewards();
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Hộp thoại xác nhận dùng chung cho mua khiên / đổi thưởng
  void _confirm(
    String message,
    Future<String?> Function() action,
    String successMessage,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xác nhận",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final error = await action();
              if (!mounted) return;
              if (error == null) _confettiController.play();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error ?? successMessage)));
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

  Widget _buildGoldCard(int gold) {
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
                  "$gold Vàng",
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
          final bool isSelected = selectedCategory == categories[index];
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
}
