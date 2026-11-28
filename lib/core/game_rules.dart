// Toàn bộ thông số cân bằng game nằm ở đây để dễ chỉnh khi cần.
class GameRules {
  // Máu tối đa: tương đương số "ngày bỏ lỡ" được phép trước khi mất chuỗi
  static const int maxHp = 3;

  // Vàng nhận được khi hoàn thành 1 nhắc nhở
  static const int goldOnTime = 10; // Hoàn thành đúng hạn
  static const int goldLate = 5; // Hoàn thành trễ hạn

  // Hồi máu khi hoàn thành đúng hạn (trễ hạn không hồi)
  static const int hpPerOnTimeTask = 1;

  // Khiên bảo vệ chuỗi
  static const int shieldPrice = 50;
  static const int maxShields = 2;

  // Phần thưởng tự đặt (giá cố định)
  static const int customRewardPrice = 20;

  // ---------------- CẤP ĐỘ ----------------
  // Mỗi 100 EXP lên 1 cấp, bắt đầu từ Lv. 1
  static const int expPerLevel = 100;

  static int levelFromExp(int exp) => (exp ~/ expPerLevel) + 1;

  // Tổng EXP cần có để đạt tới cấp `level`
  static int expForLevel(int level) => (level - 1) * expPerLevel;

  // ---------------- Ô PHẦN THƯỞNG TỰ ĐẶT ----------------
  // Cứ mỗi 5 cấp mở thêm 1 ô: Lv.5 = 1 ô, Lv.10 = 2 ô, Lv.15 = 3 ô...
  static const int levelsPerRewardSlot = 5;

  static int rewardSlotsForLevel(int level) => level ~/ levelsPerRewardSlot;

  // Cấp tiếp theo sẽ mở thêm ô mới
  static int nextRewardSlotLevel(int level) =>
      (level ~/ levelsPerRewardSlot + 1) * levelsPerRewardSlot;
}
