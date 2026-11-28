import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/database_helper.dart';
import '../../core/app_session.dart';
import '../../models/user_model.dart';
import '../../services/notification_service.dart';
import '../../view_models/gamification_view_model.dart';
import '../main_navigation.dart';
import 'forgot_password_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool isLogin = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    // Ít nhất 8 ký tự, 1 chữ hoa, 1 số, 1 ký tự đặc biệt
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return regex.hasMatch(password);
  }

  bool _isEmailValid(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("Vui lòng nhập đủ email và mật khẩu!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (isLogin) {
        await _handleLogin(email, password);
      } else {
        await _handleRegister(email, password);
      }
    } catch (e) {
      debugPrint("Lỗi đăng nhập/đăng ký: $e");
      _showMsg("Có lỗi xảy ra, vui lòng kiểm tra kết nối mạng và thử lại!");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    final user = await DatabaseHelper.instance.loginUser(email, password);
    if (user == null) {
      _showMsg("Email hoặc mật khẩu không đúng, hoặc không có kết nối mạng!");
      return;
    }
    if (!mounted) return;
    AppSession.currentUser = user; // Lưu Session

    // Xét thưởng/phạt cho các ngày đã qua kể từ lần xét gần nhất
    final summary = await context
        .read<GamificationViewModel>()
        .evaluatePastDays();

    // Xin quyền thông báo & đặt lại lịch nhắc nhở của tài khoản này
    await NotificationService().requestPermissions();
    await NotificationService().rescheduleAllForUser(user.id!);
    // Nghe việc nhóm mới được giao (Realtime)
    NotificationService().startGroupTaskListener(user.id!);
    if (!mounted) return;

    _showMsg(
      summary.hasChanges
          ? "Chào ${user.name}! ${summary.toMessage()}"
          : "Đăng nhập thành công! Chào ${user.name}",
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  Future<void> _handleRegister(String email, String password) async {
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showMsg("Vui lòng nhập tên hiển thị!");
      return;
    }
    if (!_isEmailValid(email)) {
      _showMsg("Email không hợp lệ!");
      return;
    }

    // KIỂM TRA MẬT KHẨU MẠNH
    if (!_isPasswordStrong(password)) {
      _showMsg("Mật khẩu phải từ 8 ký tự, gồm chữ Hoa, số & ký tự đặc biệt!");
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Mật khẩu xác nhận không khớp!");
      return;
    }

    final newUser = UserModel(name: name, email: email, password: password);
    final createdUser = await DatabaseHelper.instance.registerUser(newUser);

    if (createdUser == null) {
      _showMsg("Email này đã được sử dụng hoặc không có kết nối mạng!");
      return;
    }
    if (!mounted) return;
    AppSession.currentUser = createdUser; // Lưu Session
    await NotificationService().requestPermissions();
    await NotificationService()
        .cancelAll(); // Xóa lịch nhắc của tài khoản trước
    NotificationService().startGroupTaskListener(createdUser.id!);
    if (!mounted) return;
    _showMsg("Đăng ký thành công! Đang tự động đăng nhập...");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      style: const TextStyle(color: AppColors.textMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSub),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSub),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isLogin ? Icons.lock_person : Icons.person_add_alt_1,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  isLogin ? "Đăng Nhập" : "Đăng Ký",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  _buildField(
                    controller: _nameController,
                    hint: "Tên hiển thị",
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildField(
                  controller: _emailController,
                  hint: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildField(
                  controller: _passwordController,
                  hint: "Mật khẩu",
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 16),

                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordView(
                                  initialEmail: _emailController.text.trim(),
                                ),
                              ),
                            ),
                      child: const Text(
                        "Quên mật khẩu?",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),

                if (!isLogin) ...[
                  _buildField(
                    controller: _confirmPasswordController,
                    hint: "Xác nhận mật khẩu",
                    icon: Icons.lock_reset,
                    obscure: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Mật khẩu từ 8 ký tự, gồm chữ Hoa, số và ký tự đặc biệt (@\$!%*?&)",
                    style: TextStyle(color: AppColors.textSub, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withAlpha(120),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            isLogin = !isLogin;
                            _nameController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  child: Text(
                    isLogin
                        ? "Chưa có tài khoản? Đăng ký ngay"
                        : "Đã có tài khoản? Đăng nhập",
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
