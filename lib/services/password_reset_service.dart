import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';

// Quên mật khẩu bằng mã xác nhận (OTP) gửi qua email, dùng Supabase Auth.
// Luồng: gửi mã -> nhập mã + mật khẩu mới -> đổi mật khẩu.
// Cả hai hàm trả về null nếu thành công, ngược lại trả về nội dung lỗi.
class PasswordResetService {
  static GoTrueClient get _auth => SupabaseConfig.client.auth;

  static String _friendly(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('rate limit') || e.statusCode == '429') {
      return 'Bạn thao tác quá nhiều lần, vui lòng chờ vài phút rồi thử lại.';
    }
    if (m.contains('expired') || m.contains('invalid')) {
      return 'Mã không đúng hoặc đã hết hạn.';
    }
    if (m.contains('same') && m.contains('password')) {
      return 'Mật khẩu mới phải khác mật khẩu cũ.';
    }
    return e.message;
  }

  // Bước 1: gửi mã xác nhận tới email
  static Future<String?> sendCode(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim().toLowerCase());
      return null;
    } on AuthException catch (e) {
      debugPrint('sendCode: ${e.message}');
      return _friendly(e);
    } catch (e) {
      debugPrint('sendCode lỗi: $e');
      return 'Không gửi được mã. Vui lòng kiểm tra kết nối mạng.';
    }
  }

  // Bước 2: xác nhận mã rồi đặt mật khẩu mới
  static Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await _auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      if (res.session == null) return 'Mã không đúng hoặc đã hết hạn.';

      await _auth.updateUser(UserAttributes(password: newPassword));
      // Đăng xuất để người dùng đăng nhập lại bằng mật khẩu mới
      await _auth.signOut();
      return null;
    } on AuthException catch (e) {
      debugPrint('resetPassword: ${e.message}');
      return _friendly(e);
    } catch (e) {
      debugPrint('resetPassword lỗi: $e');
      return 'Không đặt lại được mật khẩu. Vui lòng thử lại.';
    }
  }
}
