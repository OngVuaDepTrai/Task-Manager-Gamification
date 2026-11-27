import 'package:provider/provider.dart';

import '../../view_models/gamification_view_model.dart';
import '../../core/app_session.dart';

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
  int get currentGold => AppSession.currentUser!.gold;
  bool purchasing = false;
  String selectedCategory = "Cá nhân";
  final List<String> categories = ["Cá nhân", "Vật phẩm", "Đồ Pet"];

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
    final game = context.watch<GamificationViewModel>();
    List<ShopItemModel> filteredRewards = [
      ...ShopItemModel.catalog,
      ...game.custom,
    ].where((r) => r.category == selectedCategory).toList();

    // Dùng Stack để đè lớp hiệu ứng tung hoa lên trên cùng giao diện
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            actions: [
              IconButton(
                tooltip: "Lịch sử đổi thưởng",
                icon: const Icon(Icons.history),
                onPressed: () => history(game),
              ),
            ],
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
                      final item = filteredRewards[index];
                      return Column(
                        children: [
                          RewardCardWidget(
                            reward: filteredRewards[index],
                            currentGold: currentGold,
                            onBuy: () => _buyReward(item),
                          ),
                          if (item.id != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => edit(item),
                                  child: const Text('Sửa'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (await confirm('Xóa ${item.name}?')) {
                                      await game.deleteReward(item.id!);
                                    }
                                  },
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          if (game.inventory.containsKey(item.slot))
                            const Text('Đã sở hữu'),
                        ],
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
                  onPressed: () => edit(null),
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

  Future<bool> confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _buyReward(ShopItemModel item) async {
    if (purchasing) return;
    purchasing = true;
    try {
      if (!await confirm("Dùng ${item.price} Vàng để mua '${item.name}'?") ||
          !mounted) {
        return;
      }
      final error = await context.read<GamificationViewModel>().buy(
        item,
        DateTime.now().microsecondsSinceEpoch.toString(),
      );
      if (!mounted) return;
      if (error == null) _confettiController.play();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Đổi thưởng thành công!')),
      );
    } finally {
      purchasing = false;
    }
  }

  void history(GamificationViewModel game) {
    final purchases = game.events.where((e) => e['kind'] == 'purchase');
    showModalBottomSheet(
      context: context,
      builder: (c) => ListView(
        children: [
          const ListTile(title: Text('Lịch sử đổi thưởng')),
          if (purchases.isEmpty)
            const ListTile(title: Text('Chưa có giao dịch')),
          for (final e in purchases)
            ListTile(
              title: Text(e['title'] as String),
              subtitle: Text(
                "${e['category']} · ${(e['stamp'] as String).substring(0, 16).replaceFirst('T', ' ')}",
              ),
              trailing: Text("${e['gold']} Vàng"),
            ),
        ],
      ),
    );
  }

  Future<void> edit(ShopItemModel? item) async {
    var name = item?.name ?? '',
        description = item?.description ?? '',
        price = item?.price.toString() ?? '',
        category = item?.category ?? selectedCategory;
    final key = GlobalKey<FormState>();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(item == null ? 'Tạo phần thưởng' : 'Sửa phần thưởng'),
        content: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên phần thưởng',
                  ),
                  onChanged: (v) => name = v,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Nhập tên' : null,
                ),
                TextFormField(
                  initialValue: description,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  onChanged: (v) => description = v,
                ),
                TextFormField(
                  initialValue: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Giá Vàng'),
                  onChanged: (v) => price = v,
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Nhập số nguyên dương'
                      : null,
                ),
                DropdownButtonFormField(
                  initialValue: category,
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => category = v ?? category,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (accepted == true && mounted) {
      await context.read<GamificationViewModel>().saveReward(
        item?.id,
        name,
        description,
        int.parse(price),
        category,
      );
      if (mounted) setState(() => selectedCategory = category);
    }
  }
}
