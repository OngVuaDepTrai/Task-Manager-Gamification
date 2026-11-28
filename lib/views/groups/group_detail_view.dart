import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_session.dart';
import '../../core/database_helper.dart';
import '../../models/friend_model.dart';
import '../../models/group_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../task/task_form_view.dart';

// Chi tiết 1 việc nhóm:
// - Nhóm trưởng: thêm / xóa thành viên, giao công việc, xóa nhóm
// - Thành viên: xem thành viên và việc đã giao, rời nhóm
class GroupDetailView extends StatefulWidget {
  final GroupModel group;
  const GroupDetailView({super.key, required this.group});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  List<UserModel> _members = [];
  // Việc đã giao trong nhóm: (task, tên người đảm nhận)
  List<MapEntry<TaskModel, String>> _tasks = [];
  bool _isLoading = true;

  bool get _isLeader => AppSession.currentUser?.id == widget.group.leaderId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = DatabaseHelper.instance;
    final list = await db.getGroupMembers(widget.group.id);
    final taskRows = await db.getGroupTasks(widget.group.id);
    if (!mounted) return;
    setState(() {
      _members = list;
      _tasks = taskRows
          .map(
            (r) => MapEntry(
              TaskModel.fromMap(r),
              (r['assignee_name'] as String?) ?? '',
            ),
          )
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _removeMember(UserModel member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          "Xóa khỏi nhóm",
          style: TextStyle(color: AppColors.textMain),
        ),
        content: Text(
          "Xóa ${member.name} khỏi nhóm \"${widget.group.name}\"?",
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hpRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && member.id != null) {
      await DatabaseHelper.instance.removeGroupMember(
        widget.group.id,
        member.id!,
      );
      _loadMembers();
    }
  }

  // Giao công việc: mở form giống màn tạo việc, có thêm ô chọn thành viên
  Future<void> _openAssignForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormView(group: widget.group)),
    );
    if (result == true) _loadMembers();
  }

  // Mở việc đã giao: nhóm trưởng được sửa, thành viên chỉ được xem
  Future<void> _openTask(TaskModel task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormView(task: task)),
    );
    if (result == true) _loadMembers();
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Hộp thoại xác nhận dùng chung (xóa nhóm, rời nhóm)
  Future<bool> _confirm(String title, String message, String okLabel) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title, style: const TextStyle(color: AppColors.textMain)),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              "Hủy",
              style: TextStyle(color: AppColors.textSub),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hpRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(okLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  // Nhóm trưởng: thêm thành viên từ danh sách bạn bè chưa có trong nhóm
  Future<void> _openAddMembersDialog() async {
    final me = AppSession.currentUser;
    if (me == null || me.id == null) return;

    final List<FriendModel> friends = await DatabaseHelper.instance.getFriends(
      me.id!,
    );
    if (!mounted) return;
    final memberIds = _members.map((m) => m.id).toSet();
    final candidates = friends
        .where((f) => !memberIds.contains(f.friendUserId))
        .toList();

    if (candidates.isEmpty) {
      _showMsg(
        friends.isEmpty
            ? "Bạn chưa có bạn bè nào để thêm vào nhóm."
            : "Tất cả bạn bè của bạn đã ở trong nhóm.",
      );
      return;
    }

    final Set<int> selected = {};
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            "Thêm thành viên",
            style: TextStyle(color: AppColors.textMain),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Chọn bạn bè (${selected.length} đã chọn)",
                  style: const TextStyle(color: AppColors.textSub),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: candidates
                        .map(
                          (f) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            checkColor: Colors.black,
                            value: selected.contains(f.friendUserId),
                            onChanged: (val) => setDialogState(() {
                              if (val == true) {
                                selected.add(f.friendUserId);
                              } else {
                                selected.remove(f.friendUserId);
                              }
                            }),
                            title: Text(
                              f.name,
                              style: const TextStyle(
                                color: AppColors.textMain,
                              ),
                            ),
                            subtitle: Text(
                              f.email,
                              style: const TextStyle(
                                color: AppColors.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                "Hủy",
                style: TextStyle(color: AppColors.textSub),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text(
                "Thêm",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (added != true || selected.isEmpty) return;
    try {
      final count = await DatabaseHelper.instance.addGroupMembers(
        group: widget.group,
        leaderName: me.name,
        userIds: selected.toList(),
      );
      if (!mounted) return;
      _showMsg(
        count > 0
            ? "Đã thêm $count thành viên vào nhóm"
            : "Những người này đã ở trong nhóm",
      );
      _loadMembers();
    } catch (e) {
      if (!mounted) return;
      _showMsg("Không thêm được thành viên: $e");
    }
  }

  // Nhóm trưởng: xóa nhóm (xóa luôn các việc đã giao trong nhóm)
  Future<void> _deleteGroup() async {
    if (!_isLeader) return;
    final ok = await _confirm(
      "Xóa nhóm",
      "Xóa nhóm \"${widget.group.name}\"? Tất cả việc đã giao trong nhóm "
          "cũng bị xóa. Không thể hoàn tác.",
      "Xóa nhóm",
    );
    if (!ok) return;
    try {
      await DatabaseHelper.instance.deleteGroup(widget.group.id);
      if (!mounted) return;
      _showMsg('Đã xóa nhóm "${widget.group.name}"');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMsg("Không xóa được nhóm: $e");
    }
  }

  // Thành viên (không phải nhóm trưởng): rời nhóm
  Future<void> _leaveGroup() async {
    final myId = AppSession.currentUser?.id;
    if (myId == null || _isLeader) return;
    final ok = await _confirm(
      "Rời nhóm",
      "Rời khỏi nhóm \"${widget.group.name}\"? Bạn sẽ không còn thấy thành viên "
          "và việc của nhóm này.",
      "Rời nhóm",
    );
    if (!ok) return;
    try {
      await DatabaseHelper.instance.leaveGroup(widget.group.id, myId);
      if (!mounted) return;
      _showMsg('Đã rời nhóm "${widget.group.name}"');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMsg("Không rời được nhóm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = AppSession.currentUser?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Chỉ nhóm trưởng mới xóa được nhóm; thành viên thì có nút rời nhóm
          if (_isLeader)
            IconButton(
              tooltip: "Xóa nhóm",
              icon: const Icon(Icons.delete_outline, color: AppColors.hpRed),
              onPressed: _deleteGroup,
            )
          else
            IconButton(
              tooltip: "Rời nhóm",
              icon: const Icon(Icons.logout, color: AppColors.hpRed),
              onPressed: _leaveGroup,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Thành viên (${_members.length})",
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Chỉ nhóm trưởng mới thêm được thành viên
                    if (_isLeader)
                      TextButton.icon(
                        onPressed: _openAddMembersDialog,
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        label: const Text(
                          "Thêm thành viên",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._members.map((m) {
                  final bool memberIsLeader = m.id == widget.group.leaderId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: memberIsLeader
                            ? AppColors.gold
                            : AppColors.primary,
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : "?",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        m.id == myId ? "${m.name} (Bạn)" : m.name,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        memberIsLeader ? "Nhóm trưởng · ${m.email}" : m.email,
                        style: const TextStyle(color: AppColors.textSub),
                      ),
                      // Chỉ nhóm trưởng được xóa thành viên (không tự xóa chính mình)
                      trailing: _isLeader && !memberIsLeader
                          ? IconButton(
                              tooltip: "Xóa khỏi nhóm",
                              icon: const Icon(
                                Icons.person_remove_outlined,
                                color: AppColors.hpRed,
                              ),
                              onPressed: () => _removeMember(m),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  "Công việc đã giao (${_tasks.length})",
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_tasks.isEmpty)
                  Text(
                    _isLeader
                        ? "Chưa giao việc nào. Bấm \"Giao công việc\" để bắt đầu."
                        : "Nhóm trưởng chưa giao việc nào.",
                    style: const TextStyle(color: AppColors.textSub),
                  ),
                ..._tasks.map((entry) {
                  final t = entry.key;
                  final assignee = t.ownerId == myId ? "Bạn" : entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: t.isOverdue()
                            ? AppColors.hpRed.withAlpha(140)
                            : Colors.transparent,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => _openTask(t),
                      leading: Icon(
                        t.isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: t.isDone ? Colors.green : AppColors.textSub,
                      ),
                      title: Text(
                        t.title,
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.bold,
                          decoration: t.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        "$assignee · ${t.time} ${t.day}/${t.month}/${t.year}",
                        style: const TextStyle(color: AppColors.textSub),
                      ),
                      trailing: Icon(
                        _isLeader ? Icons.edit_outlined : Icons.visibility_outlined,
                        color: AppColors.textSub,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ],
            ),
      floatingActionButton: _isLeader
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: _openAssignForm,
              icon: const Icon(Icons.assignment_ind, color: Colors.black),
              label: const Text(
                "Giao công việc",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
