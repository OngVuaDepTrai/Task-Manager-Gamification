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
}
