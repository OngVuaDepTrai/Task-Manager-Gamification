import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/friend_model.dart';
import '../../models/user_model.dart';

class SharedTaskView extends StatefulWidget {
  const SharedTaskView({super.key});

  @override
  State<SharedTaskView> createState() => _SharedTaskViewState();
}

class _SharedTaskViewState extends State<SharedTaskView> {
  List<FriendModel> _friends = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _sharedTasks = [
    {"title": "Vẽ UML Diagram", "assignee": "Minh Nhật", "done": true},
    {"title": "Làm giao diện Flutter", "assignee": "Thanh Tài", "done": false},
    {"title": "Code Database SQLite", "assignee": "Tấn Thành", "done": false},
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final user = AppSession.currentUser;
    if (user != null && user.id != null) {
      final list = await DatabaseHelper.instance.getFriends(user.id!);
      if (!mounted) return;
      setState(() {
        _friends = list;
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openAddFriendSheet() {
    final user = AppSession.currentUser;
    if (user == null || user.id == null) return;

    final TextEditingController searchController = TextEditingController();
    List<UserModel> candidates = [];
    bool searching = true;

    Future<void> runSearch(String query, StateSetter setSheetState) async {
      setSheetState(() => searching = true);
      final found = await DatabaseHelper.instance.searchUsers(query, user.id!);
      setSheetState(() {
        candidates = found;
        searching = false;
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (searching && candidates.isEmpty) {
              runSearch("", setSheetState);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kết bạn để giao việc chung",
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: AppColors.textMain),
                      onChanged: (val) => runSearch(val, setSheetState),
                      decoration: InputDecoration(
                        hintText: "Tìm theo tên hoặc email...",
                        hintStyle: const TextStyle(color: AppColors.textSub),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSub,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: searching
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : candidates.isEmpty
                          ? const Center(
                              child: Text(
                                "Không tìm thấy người dùng nào.",
                                style: TextStyle(color: AppColors.textSub),
                              ),
                            )
                          : ListView.builder(
                              itemCount: candidates.length,
                              itemBuilder: (context, idx) {
                                final cand = candidates[idx];
                                final alreadyFriend = _friends.any(
                                  (f) => f.friendUserId == cand.id,
                                );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      cand.name.isNotEmpty
                                          ? cand.name[0].toUpperCase()
                                          : "U",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    cand.name,
                                    style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${cand.email} • Chuỗi ${cand.currentStreak} ngày",
                                    style: const TextStyle(
                                      color: AppColors.textSub,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: alreadyFriend
                                      ? OutlinedButton(
                                          onPressed: () async {
                                            if (cand.id != null) {
                                              await DatabaseHelper.instance
                                                  .removeFriend(
                                                    user.id!,
                                                    cand.id!,
                                                  );
                                              await _loadFriends();
                                              setSheetState(() {});
                                            }
                                          },
                                          child: const Text(
                                            "Đã kết bạn",
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                          ),
                                          onPressed: () async {
                                            if (cand.id != null) {
                                              // Lấy messenger trước khi await
                                              final messenger =
                                                  ScaffoldMessenger.of(context);
                                              await DatabaseHelper.instance
                                                  .addFriend(
                                                    user.id!,
                                                    cand.id!,
                                                  );
                                              await _loadFriends();
                                              setSheetState(() {});
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Đã kết bạn với ${cand.name}!",
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: const Text(
                                            "Kết bạn",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAssignTaskDialog() {
    final titleController = TextEditingController();
    String assignee = _friends.isNotEmpty
        ? _friends.first.name
        : (AppSession.currentUser?.name ?? "Bạn");

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = <String>[
              if (AppSession.currentUser != null) AppSession.currentUser!.name,
              ..._friends.map((f) => f.name),
            ];
            if (!options.contains(assignee) && options.isNotEmpty) {
              assignee = options.first;
            }

            return AlertDialog(
              backgroundColor: AppColors.card,
              title: const Text(
                "Giao nhiệm vụ chung",
                style: TextStyle(color: AppColors.textMain),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: const InputDecoration(
                      hintText: "Tên nhiệm vụ chung...",
                      hintStyle: TextStyle(color: AppColors.textSub),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (options.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: assignee,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: AppColors.textMain),
                      decoration: const InputDecoration(
                        labelText: "Phụ trách",
                        labelStyle: TextStyle(color: AppColors.textSub),
                      ),
                      items: options
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => assignee = val);
                        }
                      },
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      setState(() {
                        _sharedTasks.add({
                          "title": titleController.text.trim(),
                          "assignee": assignee,
                          "done": false,
                        });
                      });
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text(
                    "Giao việc",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
          'Bạn bè & Việc nhóm',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Kết bạn",
            onPressed: _openAddFriendSheet,
            icon: const Icon(Icons.person_add, color: AppColors.primary),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bạn bè đã kết nối (${_friends.length})",
                            style: const TextStyle(
                              color: AppColors.textSub,
                              fontSize: 14,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openAddFriendSheet,
                            icon: const Icon(
                              Icons.person_add_alt_1,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              "Kết bạn",
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _friends.isEmpty
                          ? const Text(
                              "Chưa có bạn bè. Bấm 'Kết bạn' để thêm và mời vào nhiệm vụ chung.",
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 13,
                              ),
                            )
                          : SizedBox(
                              height: 44,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _friends.length,
                                itemBuilder: (context, idx) {
                                  final f = _friends[idx];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primary,
                                          child: Text(
                                            f.name.isNotEmpty
                                                ? f.name[0].toUpperCase()
                                                : "B",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          f.name,
                                          style: const TextStyle(
                                            color: AppColors.textMain,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sharedTasks.length,
                    itemBuilder: (context, index) {
                      final task = _sharedTasks[index];
                      final bool done = task["done"] as bool;
                      return GestureDetector(
                        onTap: () => setState(() => task["done"] = !done),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done ? Colors.green : AppColors.textSub,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task["title"] as String,
                                      style: TextStyle(
                                        color: done
                                            ? AppColors.textSub
                                            : AppColors.textMain,
                                        fontSize: 16,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Phụ trách: ${task["assignee"]}",
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openAssignTaskDialog,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          "Giao việc",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
