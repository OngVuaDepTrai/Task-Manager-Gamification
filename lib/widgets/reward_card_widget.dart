import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/shop_item_model.dart';

class RewardCardWidget extends StatelessWidget {
  final ShopItemModel reward;
  final int currentGold;
  final VoidCallback onBuy;
  // Nếu khác null: khóa nút mua và hiển thị lý do (VD: "Đã đủ")
  final String? blockedLabel;
  final String buyLabel;
  final VoidCallback? onLongPress;

  const RewardCardWidget({
    super.key,
    required this.reward,
    required this.currentGold,
    required this.onBuy,
    this.blockedLabel,
    this.buyLabel = "Mua",
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bool canBuy = blockedLabel == null && currentGold >= reward.price;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
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
            child: Icon(reward.icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reward.description,
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
                      "${reward.price}",
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
              onPressed: canBuy ? onBuy : null,
              child: Text(
                canBuy ? buyLabel : (blockedLabel ?? "Thiếu vàng"),
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
    ),
    );
  }
}
