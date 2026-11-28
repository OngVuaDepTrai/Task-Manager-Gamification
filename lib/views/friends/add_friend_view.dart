import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/user_model.dart';

// Màn Thêm bạn bè: nhập email -> nếu đúng thì hiện Tên + Email + nút Thêm
class AddFriendView extends StatefulWidget {
  const AddFriendView({super.key});

  @override
  State<AddFriendView> createState() => _AddFriendViewState();
}

class _AddFriendViewState extends State<AddFriendView> {
  final TextEditingController _emailController = TextEditingController();
  Timer? _debounce;

  UserModel? _foundUser;
  String _status = 'none'; // friend | sent | received | none
  bool _searched = false;
  bool _isSelf = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _lookup(value));
  }

  Future<void> _lookup(String value) async {
    final email = value.trim();
    final me = AppSession.currentUser;
    if (me == null || me.id == null) return;

    if (!email.contains('@')) {
      setState(() {
        _foundUser = null;
        _searched = false;
      });
      return;
    }

    final user = await DatabaseHelper.instance.getUserByEmail(email);
    String status = 'none';
    if (user != null && user.id != me.id) {
      status = await DatabaseHelper.instance.getFriendStatus(me.id!, user.id!);
    }
    if (!mounted) return;
    setState(() {
      _foundUser = user;
      _isSelf = user != null && user.id == me.id;
      _status = status;
      _searched = true;
    });
  }

  Future<void> _sendRequest() async {
    final me = AppSession.currentUser;
    final target = _foundUser;
    if (me?.id == null || target?.id == null) return;

    final wasReceived = _status == 'received';
    final ok = await DatabaseHelper.instance.sendFriendRequest(
      me!.id!,
      target!.id!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !ok
              ? "Không thể gửi lời mời"
              : wasReceived
              ? "Đã kết bạn với ${target.name}!"
              : "Đã gửi lời mời kết bạn tới ${target.name}",
        ),
      ),
    );
    _lookup(_emailController.text);
  }

  String get _buttonLabel {
    switch (_status) {
      case 'friend':
        return "Bạn bè";
      case 'sent':
        return "Đã gửi";
      case 'received':
        return "Chấp nhận";
      default:
        return "Thêm";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Thêm bạn bè",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              onChanged: _onEmailChanged,
              style: const TextStyle(color: AppColors.textMain),
              decoration: InputDecoration(
                hintText: "Nhập email của bạn bè...",
                hintStyle: const TextStyle(color: AppColors.textSub),
                prefixIcon: const Icon(
                  Icons.alternate_email,
                  color: AppColors.textSub,
                ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_searched && _foundUser == null)
              const Text(
                "Không tìm thấy tài khoản với email này.",
                style: TextStyle(color: AppColors.textSub),
              ),
            if (_foundUser != null && _isSelf)
              const Text(
                "Đây là email của bạn.",
                style: TextStyle(color: AppColors.textSub),
              ),
            if (_foundUser != null && !_isSelf) _buildResultCard(_foundUser!),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(UserModel user) {
    final bool canPress = _status == 'none' || _status == 'received';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: AppColors.textSub),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canPress
                  ? AppColors.primary
                  : Colors.grey.shade800,
            ),
            onPressed: canPress ? _sendRequest : null,
            child: Text(
              _buttonLabel,
              style: TextStyle(
                color: canPress ? Colors.black : AppColors.textSub,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
