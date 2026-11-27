import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/friend_model.dart';
import '../models/group_model.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'supabase_config.dart';

// Bản Supabase: giữ NGUYÊN tên hàm và kiểu trả về của bản SQLite cũ
// để các View / ViewModel không phải sửa.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const String dailyCategoryName = 'Hàng ngày';
  static const String groupCategoryName = 'Nhóm';

  DatabaseHelper._init();

  SupabaseClient get _c => SupabaseConfig.client;
  GoTrueClient get _auth => SupabaseConfig.client.auth;

  String formatDateKey(int day, int month, int year) {
    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  // Profile không có cột password -> bù chuỗi rỗng để UserModel.fromMap không lỗi
  UserModel _userFrom(Map<String, dynamic> row) =>
      UserModel.fromMap({...row, 'password': ''});

  Future<Map<int, Map<String, dynamic>>> _profilesByIds(
    Iterable<int> ids,
  ) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return {};
    final rows = await _c.from('profiles').select().inFilter('id', list);
    return {for (final r in rows) r['id'] as int: Map<String, dynamic>.from(r)};
  }

  // ====================== USER LOGIC ======================
  Future<UserModel?> registerUser(UserModel user) async {
    try {
      final email = user.email.trim().toLowerCase();
      final res = await _auth.signUp(
        email: email,
        password: user.password,
        data: {'name': user.name},
      );
      // Nếu dự án còn bật "Confirm email" thì chưa có session -> thử đăng nhập
      if (res.session == null) {
        await _auth.signInWithPassword(email: email, password: user.password);
      }
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      final row = await _c
          .from('profiles')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();
      if (row == null) return null;

      // Tài khoản mới: bắt đầu xét từ hôm nay (đánh dấu hôm qua là đã xét)
      final y = DateTime.now().subtract(const Duration(days: 1));
      final yKey = formatDateKey(y.day, y.month, y.year);
      await _c
          .from('profiles')
          .update({'lastCheckedDate': yKey})
          .eq('id', row['id']);

      final created = _userFrom({...row, 'lastCheckedDate': yKey});
      await getCategories(created.id!);
      return created;
    } on AuthException catch (e) {
      debugPrint('registerUser: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('registerUser lỗi: $e');
      return null;
    }
  }

  Future<UserModel?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final authUser = _auth.currentUser;
      if (authUser == null) return null;
      final row = await _c
          .from('profiles')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();
      if (row == null) return null;
      final user = _userFrom(row);
      if (user.id != null) await getCategories(user.id!);
      return user;
    } on AuthException catch (e) {
      debugPrint('loginUser: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('loginUser lỗi: $e');
      return null;
    }
  }

  // Khôi phục phiên đăng nhập đã lưu (dùng khi mở lại app)
  Future<UserModel?> restoreSession() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;
      final row = await _c
          .from('profiles')
          .select()
          .eq('auth_id', authUser.id)
          .maybeSingle();
      if (row == null) return null;
      final user = _userFrom(row);
      if (user.id != null) await getCategories(user.id!);
      return user;
    } catch (e) {
      debugPrint('restoreSession lỗi: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('signOut lỗi: $e');
    }
  }

  Future<int> updateUserStats(UserModel user) async {
    if (user.id == null) return 0;
    try {
      await _c
          .from('profiles')
          .update({
            'exp': user.exp,
            'gold': user.gold,
            'currentStreak': user.currentStreak,
            'longestStreak': user.longestStreak,
            'avatarPath': user.avatarPath,
            'hp': user.hp,
            'shields': user.shields,
            'lastCheckedDate': user.lastCheckedDate,
          })
          .eq('id', user.id!);
      return 1;
    } catch (e) {
      debugPrint('updateUserStats lỗi: $e');
      return 0;
    }
  }

  Future<List<UserModel>> searchUsers(String query, int currentUserId) async {
    final q = query.trim();
    var builder = _c.from('profiles').select().neq('id', currentUserId);
    if (q.isNotEmpty) {
      builder = builder.or('name.ilike.%$q%,email.ilike.%$q%');
    }
    final rows = await builder;
    return rows.map((r) => _userFrom(r)).toList();
  }

  // BXH chuỗi: bản thân + bạn bè đã kết bạn
  Future<List<UserModel>> getStreakLeaderboard(int userId) async {
    final fr = await _c
        .from('friends')
        .select('friend_user_id')
        .eq('user_id', userId)
        .eq('status', 'accepted');
    final ids = <int>{userId, ...fr.map((r) => r['friend_user_id'] as int)};
    final rows = await _c
        .from('profiles')
        .select()
        .inFilter('id', ids.toList())
        .order('currentStreak', ascending: false)
        .order('longestStreak', ascending: false)
        .order('name', ascending: true);
    return rows.map((r) => _userFrom(r)).toList();
  }

  // ====================== FRIEND LOGIC ======================
  Future<UserModel?> getUserByEmail(String email) async {
    final row = await _c
        .from('profiles')
        .select()
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();
    return row == null ? null : _userFrom(row);
  }

  // 'friend' | 'sent' | 'received' | 'none'
  Future<String> getFriendStatus(int userId, int otherId) async {
    final mine = await _c
        .from('friends')
        .select('status')
        .eq('user_id', userId)
        .eq('friend_user_id', otherId)
        .maybeSingle();
    if (mine != null) {
      return mine['status'] == 'accepted' ? 'friend' : 'sent';
    }
    final theirs = await _c
        .from('friends')
        .select('status')
        .eq('user_id', otherId)
        .eq('friend_user_id', userId)
        .eq('status', 'pending')
        .maybeSingle();
    return theirs != null ? 'received' : 'none';
  }

  Future<bool> sendFriendRequest(int userId, int friendUserId) async {
    if (userId == friendUserId) return false;
    try {
      final status = await getFriendStatus(userId, friendUserId);
      if (status == 'received') {
        await acceptFriendRequestFrom(friendUserId, userId);
        return true;
      }
      if (status != 'none') return false;
      await _c.from('friends').insert({
        'user_id': userId,
        'friend_user_id': friendUserId,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      debugPrint('sendFriendRequest lỗi: $e');
      return false;
    }
  }

  Future<List<FriendModel>> getIncomingFriendRequests(int userId) async {
    final rows = await _c
        .from('friends')
        .select()
        .eq('friend_user_id', userId)
        .eq('status', 'pending')
        .order('id', ascending: false);
    final profiles = await _profilesByIds(rows.map((r) => r['user_id'] as int));
    final result = <FriendModel>[];
    for (final r in rows) {
      final p = profiles[r['user_id']];
      if (p == null) continue;
      result.add(
        FriendModel.fromMap({
          ...r,
          'name': p['name'],
          'email': p['email'],
          'currentStreak': p['currentStreak'],
        }),
      );
    }
    return result;
  }

  Future<void> acceptFriendRequestFrom(int senderId, int receiverId) async {
    await _c
        .from('friends')
        .update({'status': 'accepted'})
        .eq('user_id', senderId)
        .eq('friend_user_id', receiverId);
    // Quan hệ chiều ngược lại để cả 2 đều thấy nhau
    await _c.from('friends').upsert({
      'user_id': receiverId,
      'friend_user_id': senderId,
      'status': 'accepted',
    }, onConflict: 'user_id,friend_user_id');
  }

  Future<void> declineFriendRequestFrom(int senderId, int receiverId) async {
    await _c
        .from('friends')
        .delete()
        .eq('user_id', senderId)
        .eq('friend_user_id', receiverId)
        .eq('status', 'pending');
  }

  Future<void> removeFriend(int userId, int friendUserId) async {
    await _c
        .from('friends')
        .delete()
        .or(
          'and(user_id.eq.$userId,friend_user_id.eq.$friendUserId),'
          'and(user_id.eq.$friendUserId,friend_user_id.eq.$userId)',
        );
  }

  Future<List<FriendModel>> getFriends(int userId) async {
    final rows = await _c
        .from('friends')
        .select()
        .eq('user_id', userId)
        .eq('status', 'accepted');
    final profiles = await _profilesByIds(
      rows.map((r) => r['friend_user_id'] as int),
    );
    final result = <FriendModel>[];
    for (final r in rows) {
      final p = profiles[r['friend_user_id']];
      if (p == null) continue;
      result.add(
        FriendModel.fromMap({
          ...r,
          'name': p['name'],
          'email': p['email'],
          'currentStreak': p['currentStreak'],
        }),
      );
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  // ====================== TASK LOGIC ======================
  Future<int> insertTask(TaskModel task, int userId) async {
    final map = task.toMap(userId)..remove('id');
    final row = await _c.from('tasks').insert(map).select('id').single();
    return row['id'] as int;
  }

  Future<int> updateTask(TaskModel task, int userId) async {
    if (task.id == null) return 0;
    final map = task.toMap(userId)..remove('id');
    await _c.from('tasks').update(map).eq('id', task.id!).eq('user_id', userId);
    return 1;
  }

  Future<int> deleteTask(int taskId, int userId) async {
    // task_completions tự xóa theo (ON DELETE CASCADE)
    await _c.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
    return 1;
  }

  Future<List<TaskModel>> getTasks(int userId) async {
    final rows = await _c.from('tasks').select().eq('user_id', userId);
    return rows.map((m) => TaskModel.fromMap(m)).toList();
  }

  Future<List<TaskModel>> getTasksForDate(
    int userId,
    int day,
    int month,
    int year,
  ) async {
    final dateKey = formatDateKey(day, month, year);

    final results = await Future.wait([
      _c.from('tasks').select().eq('user_id', userId),
      _c
          .from('task_completions')
          .select('task_id')
          .eq('user_id', userId)
          .eq('date_key', dateKey),
    ]);
    final rawTasks = results[0];
    final completedIds = {for (final r in results[1]) r['task_id'] as int};

    final List<TaskModel> result = [];
    for (final map in rawTasks) {
      final task = TaskModel.fromMap(map);
      if (task.isDaily) {
        result.add(
          task.copyWith(
            day: day,
            month: month,
            year: year,
            isDone: task.id != null && completedIds.contains(task.id),
          ),
        );
      } else if (task.day == day && task.month == month && task.year == year) {
        result.add(task);
      }
    }
    return result;
  }

  Future<void> setTaskCompletionForDate({
    required int userId,
    required TaskModel task,
    required bool isDone,
    required int day,
    required int month,
    required int year,
  }) async {
    if (task.isDaily && task.id != null) {
      final dateKey = formatDateKey(day, month, year);
      if (isDone) {
        await _c.from('task_completions').upsert({
          'task_id': task.id,
          'user_id': userId,
          'date_key': dateKey,
        }, onConflict: 'task_id,date_key');
      } else {
        await _c
            .from('task_completions')
            .delete()
            .eq('task_id', task.id!)
            .eq('user_id', userId)
            .eq('date_key', dateKey);
      }
    } else if (task.id != null) {
      await updateTaskStatus(task.id!, isDone);
    }
  }

  Future<int> updateTaskStatus(int taskId, bool isDone) async {
    await _c.from('tasks').update({'isDone': isDone ? 1 : 0}).eq('id', taskId);
    return 1;
  }

  // ====================== CATEGORY LOGIC ======================
  Future<List<Map<String, dynamic>>> getCategories(int userId) async {
    var maps = await _c.from('categories').select().eq('user_id', userId);

    if (maps.isEmpty) {
      final defaults = [
        {'name': dailyCategoryName, 'isDaily': 1},
        {'name': 'Đại học', 'isDaily': 0},
        {'name': 'Cá nhân', 'isDaily': 0},
        {'name': 'Thể thao', 'isDaily': 0},
        {'name': 'Gia đình', 'isDaily': 0},
      ];
      await _c
          .from('categories')
          .upsert(
            defaults.map((d) => {'user_id': userId, ...d}).toList(),
            onConflict: 'user_id,name',
            ignoreDuplicates: true,
          );
      maps = await _c.from('categories').select().eq('user_id', userId);
    } else if (!maps.any((c) => c['name'] == dailyCategoryName)) {
      await _c
          .from('categories')
          .upsert(
            {'user_id': userId, 'name': dailyCategoryName, 'isDaily': 1},
            onConflict: 'user_id,name',
            ignoreDuplicates: true,
          );
      maps = await _c.from('categories').select().eq('user_id', userId);
    }

    final sorted = List<Map<String, dynamic>>.from(maps);
    sorted.sort((a, b) {
      if (a['name'] == dailyCategoryName) return -1;
      if (b['name'] == dailyCategoryName) return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return sorted;
  }

  Future<int> insertCategory(
    int userId,
    String name, {
    bool isDaily = false,
  }) async {
    final cleanName = name.trim();
    final dailyFlag = (cleanName == dailyCategoryName || isDaily) ? 1 : 0;
    await _c
        .from('categories')
        .upsert(
          {'user_id': userId, 'name': cleanName, 'isDaily': dailyFlag},
          onConflict: 'user_id,name',
          ignoreDuplicates: true,
        );
    final row = await _c
        .from('categories')
        .select('id')
        .eq('user_id', userId)
        .eq('name', cleanName)
        .maybeSingle();
    return row == null ? 0 : row['id'] as int;
  }

  Future<void> updateCategoryAndTasks(
    int userId,
    int categoryId,
    String oldName,
    String newName,
  ) async {
    if (oldName == dailyCategoryName) return;
    final clean = newName.trim();
    await _c
        .from('categories')
        .update({'name': clean})
        .eq('id', categoryId)
        .eq('user_id', userId);
    await _c
        .from('tasks')
        .update({'category': clean})
        .eq('user_id', userId)
        .eq('category', oldName);
  }

  Future<void> deleteCategoryAndTasks(
    int userId,
    int categoryId,
    String categoryName,
  ) async {
    if (categoryName == dailyCategoryName) return;
    await _c
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', userId);
    await _c
        .from('tasks')
        .update({'category': 'Khác', 'isDaily': 0})
        .eq('user_id', userId)
        .eq('category', categoryName);
  }

  // ====================== CUSTOM REWARD LOGIC ======================
  Future<List<Map<String, dynamic>>> getCustomRewards(int userId) async {
    final rows = await _c
        .from('custom_rewards')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> insertCustomReward(
    int userId,
    String name,
    String description,
  ) async {
    final row = await _c
        .from('custom_rewards')
        .insert({
          'user_id': userId,
          'name': name.trim(),
          'description': description.trim(),
        })
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<int> deleteCustomReward(int rewardId, int userId) async {
    await _c
        .from('custom_rewards')
        .delete()
        .eq('id', rewardId)
        .eq('user_id', userId);
    return 1;
  }

  // ====================== STATISTICS ======================
  Future<int> countCompletedTasks(int userId) async {
    final results = await Future.wait([
      _c
          .from('tasks')
          .select('id')
          .eq('user_id', userId)
          .eq('isDaily', 0)
          .eq('isDone', 1),
      _c.from('task_completions').select('task_id').eq('user_id', userId),
    ]);
    return results[0].length + results[1].length;
  }

  // ====================== GROUP LOGIC ======================
  Future<int> createGroup(
    String name,
    int leaderId,
    List<int> memberIds,
  ) async {
    final g = await _c
        .from('groups')
        .insert({'name': name.trim(), 'leader_id': leaderId})
        .select('id')
        .single();
    final groupId = g['id'] as int;
    try {
      await _c
          .from('group_members')
          .upsert(
            {
              leaderId,
              ...memberIds,
            }.map((uid) => {'group_id': groupId, 'user_id': uid}).toList(),
            onConflict: 'group_id,user_id',
            ignoreDuplicates: true,
          );
    } catch (e) {
      await _c.from('groups').delete().eq('id', groupId); // dọn nhóm dở dang
      rethrow;
    }
    return groupId;
  }

  Future<List<GroupModel>> getGroupsForUser(int userId) async {
    final mem = await _c
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    final ids = mem.map((r) => r['group_id'] as int).toList();
    if (ids.isEmpty) return [];

    final groups = await _c
        .from('groups')
        .select()
        .inFilter('id', ids)
        .order('id', ascending: false);
    final allMembers = await _c
        .from('group_members')
        .select('group_id')
        .inFilter('group_id', ids);
    final counts = <int, int>{};
    for (final r in allMembers) {
      final gid = r['group_id'] as int;
      counts[gid] = (counts[gid] ?? 0) + 1;
    }
    final leaders = await _profilesByIds(
      groups.map((g) => g['leader_id'] as int),
    );

    return groups
        .map(
          (g) => GroupModel.fromMap({
            'id': g['id'],
            'name': g['name'],
            'leader_id': g['leader_id'],
            'leader_name': leaders[g['leader_id']]?['name'] ?? '',
            'member_count': counts[g['id']] ?? 0,
          }),
        )
        .toList();
  }

  Future<List<UserModel>> getGroupMembers(int groupId) async {
    final mem = await _c
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);
    final profiles = await _profilesByIds(mem.map((r) => r['user_id'] as int));
    final list = profiles.values.map((p) => _userFrom(p)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> removeGroupMember(int groupId, int userId) async {
    await _c
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<GroupModel?> getGroupById(int groupId) async {
    final g = await _c.from('groups').select().eq('id', groupId).maybeSingle();
    if (g == null) return null;
    final members = await _c
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId);
    final leaders = await _profilesByIds([g['leader_id'] as int]);
    return GroupModel.fromMap({
      'id': g['id'],
      'name': g['name'],
      'leader_id': g['leader_id'],
      'leader_name': leaders[g['leader_id']]?['name'] ?? '',
      'member_count': members.length,
    });
  }

  // Việc đã giao trong nhóm, kèm tên người đảm nhận (assignee_name)
  Future<List<Map<String, dynamic>>> getGroupTasks(int groupId) async {
    final rows = await _c
        .from('tasks')
        .select()
        .eq('group_id', groupId)
        .order('year', ascending: false)
        .order('month', ascending: false)
        .order('day', ascending: false)
        .order('time', ascending: true);
    final profiles = await _profilesByIds(rows.map((r) => r['user_id'] as int));
    return rows
        .map(
          (r) => <String, dynamic>{
            ...r,
            'assignee_name': profiles[r['user_id']]?['name'] ?? '',
          },
        )
        .toList();
  }

  Future<void> _notifyAssignee({
    required int assigneeId,
    required String leaderName,
    required String groupName,
    required String taskTitle,
  }) async {
    await _c.from('notifications').insert({
      'user_id': assigneeId,
      'type': 'task_assigned',
      'message':
          '$leaderName (nhóm trưởng "$groupName") đã giao cho bạn: "$taskTitle"',
      'is_read': 0,
    });
  }

  Future<int> assignGroupTask({
    required GroupModel group,
    required int leaderId,
    required String leaderName,
    required int assigneeId,
    required TaskModel task,
  }) async {
    final groupTask = task.copyWith(
      category: groupCategoryName,
      isDaily: false,
      groupId: group.id,
      groupName: group.name,
    );
    final map = groupTask.toMap(assigneeId)..remove('id');
    final row = await _c.from('tasks').insert(map).select('id').single();
    if (assigneeId != leaderId) {
      await _notifyAssignee(
        assigneeId: assigneeId,
        leaderName: leaderName,
        groupName: group.name,
        taskTitle: groupTask.title,
      );
    }
    return row['id'] as int;
  }

  Future<void> updateGroupTask({
    required GroupModel group,
    required int leaderId,
    required String leaderName,
    required int oldAssigneeId,
    required int newAssigneeId,
    required TaskModel task,
  }) async {
    if (task.id == null) return;
    final groupTask = task.copyWith(
      category: groupCategoryName,
      isDaily: false,
      groupId: group.id,
      groupName: group.name,
    );
    final map = groupTask.toMap(newAssigneeId)..remove('id');
    await _c
        .from('tasks')
        .update(map)
        .eq('id', task.id!)
        .eq('group_id', group.id);
    if (newAssigneeId != oldAssigneeId && newAssigneeId != leaderId) {
      await _notifyAssignee(
        assigneeId: newAssigneeId,
        leaderName: leaderName,
        groupName: group.name,
        taskTitle: groupTask.title,
      );
    }
  }

  Future<void> deleteGroupTask(int taskId) async {
    await _c.from('tasks').delete().eq('id', taskId);
  }

  // ====================== NOTIFICATION LOGIC ======================
  Future<List<NotificationModel>> getNotifications(int userId) async {
    final rows = await _c
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false);
    return rows.map((r) {
      // created_at từ server là UTC -> đổi sang giờ máy để hiển thị đúng
      final t = DateTime.tryParse('${r['created_at']}')?.toLocal();
      return NotificationModel.fromMap({
        ...r,
        'created_at': t?.toIso8601String() ?? '',
      });
    }).toList();
  }

  Future<void> markAllNotificationsRead(int userId) async {
    await _c
        .from('notifications')
        .update({'is_read': 1})
        .eq('user_id', userId)
        .eq('is_read', 0);
  }

  Future<int> countUnseen(int userId) async {
    final results = await Future.wait([
      _c
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', 0),
      _c
          .from('friends')
          .select('id')
          .eq('friend_user_id', userId)
          .eq('status', 'pending'),
    ]);
    return results[0].length + results[1].length;
  }
}
