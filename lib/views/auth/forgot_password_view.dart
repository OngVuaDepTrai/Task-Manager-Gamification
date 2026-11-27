import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/password_reset_service.dart';

// Màn Quên mật khẩu: nhập email -> nhận mã qua email -> nhập mã + mật khẩu mới
class ForgotPasswordView extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordView({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  int _cooldown = 0; // Giây chờ trước khi được gửi lại mã
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  // Cùng quy tắc với màn Đăng ký
  bool _isPasswordStrong(String password) =>
      RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
          .hasMatch(password);

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    if (_isLoading || _cooldown > 0) return;
    final email = _emailController.text.trim().toLowerCase();
    if (!_isEmailValid(email)) {
      _showMsg('Email không hợp lệ!');
      return;
    }
    setState(() => _isLoading = true);
    final error = await PasswordResetService.sendCode(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMsg(error);
      return;
    }
    setState(() => _codeSent = true);
    _startCooldown();
    _showMsg(
      'Nếu email đã đăng ký, mã xác nhận đã được gửi. '
      'Hãy kiểm tra cả hộp thư Spam.',
    );
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    final email = _emailController.text.trim().toLowerCase();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (code.isEmpty) {
      _showMsg('Vui lòng nhập mã xác nhận trong email!');
      return;
    }
    if (!_isPasswordStrong(password)) {
      _showMsg('Mật khẩu phải từ 8 ký tự, gồm chữ Hoa, số & ký tự đặc biệt!');
      return;
    }
    if (password != confirm) {
      _showMsg('Mật khẩu xác nhận không khớp!');
      return;
    }

    setState(() => _isLoading = true);
    final error = await PasswordResetService.resetPassword(
      email: email,
      code: code,
      newPassword: password,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMsg(error);
      return;
    }
    _showMsg('Đặt lại mật khẩu thành công! Hãy đăng nhập lại.');
    Navigator.pop(context);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      enabled: enabled && !_isLoading,
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

  Widget _buildPrimaryButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withAlpha(120),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _codeSent
                    ? 'Nhập mã xác nhận đã gửi tới email và đặt mật khẩu mới.'
                    : 'Nhập email đã đăng ký, chúng tôi sẽ gửi mã xác nhận để bạn đặt lại mật khẩu.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSub, height: 1.4),
              ),
              const SizedBox(height: 24),
              _buildField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_codeSent,
              ),
              const SizedBox(height: 16),
              if (!_codeSent)
                _buildPrimaryButton('GỬI MÃ XÁC NHẬN', _sendCode)
              else ...[
                _buildField(
                  controller: _codeController,
                  hint: 'Mã xác nhận (trong email)',
                  icon: Icons.pin,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  hint: 'Mật khẩu mới',
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmController,
                  hint: 'Xác nhận mật khẩu mới',
                  icon: Icons.lock_reset,
                  obscure: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mật khẩu từ 8 ký tự, gồm chữ Hoa, số và ký tự đặc biệt (@\$!%*?&)',
                  style: TextStyle(color: AppColors.textSub, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildPrimaryButton('ĐẶT LẠI MẬT KHẨU', _resetPassword),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (_isLoading || _cooldown > 0) ? null : _sendCode,
                  child: Text(
                    _cooldown > 0
                        ? 'Gửi lại mã sau ${_cooldown}s'
                        : 'Gửi lại mã',
                    style: TextStyle(
                      color: _cooldown > 0
                          ? AppColors.textSub
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
