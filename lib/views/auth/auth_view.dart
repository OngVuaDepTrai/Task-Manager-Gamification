import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/database_helper.dart';
import '../../core/app_session.dart';
import '../../models/user_model.dart';
import '../main_navigation.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool isLogin = true;

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

  Future<void> _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMsg("Vui lòng nhập đủ email và mật khẩu!");
      return;
    }

    if (isLogin) {
      final user = await DatabaseHelper.instance.loginUser(email, password);
      if (user != null) {
        if (!mounted) return;
        AppSession.currentUser = user; // Lưu Session
        _showMsg("Đăng nhập thành công! Chào ${user.name}");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        _showMsg("Email hoặc mật khẩu không đúng!");
      }
    } else {
      final name = _nameController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (name.isEmpty) {
        _showMsg("Vui lòng nhập tên hiển thị!");
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

      if (createdUser != null) {
        if (!mounted) return;
        AppSession.currentUser = createdUser; // Lưu Session
        _showMsg("Đăng ký thành công! Đang tự động đăng nhập...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      } else {
        _showMsg("Email này đã được sử dụng!");
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: "Tên hiển thị",
                      hintStyle: const TextStyle(color: AppColors.textSub),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: const TextStyle(color: AppColors.textSub),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: "Mật khẩu",
                    hintStyle: const TextStyle(color: AppColors.textSub),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppColors.textSub,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!isLogin) ...[
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: "Xác nhận mật khẩu",
                      hintStyle: const TextStyle(color: AppColors.textSub),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_reset,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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
                  onPressed: () {
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
