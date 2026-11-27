import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/friend_model.dart';
import '../models/group_model.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import 'game_rules.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String dailyCategoryName = 'Hàng ngày';
  // Danh mục cố định của việc nhóm được giao (không nằm trong bảng categories)
  static const String groupCategoryName = 'Nhóm';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gamification_app_v7.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Nâng cấp DB cũ (version 1) lên version 2: thêm HP, khiên, ngày xét và bảng phần thưởng
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE users ADD COLUMN hp INTEGER DEFAULT ${GameRules.maxHp}',
      );
      await db.execute(
        'ALTER TABLE users ADD COLUMN shields INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE users ADD COLUMN lastCheckedDate TEXT');
      await _createRewardsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN group_id INTEGER');
      await db.execute('ALTER TABLE tasks ADD COLUMN group_name TEXT');
      await _createGroupTables(db);
    }
    if (oldVersion < 4) {
      await _seedSampleFriends(db);
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tasks ADD COLUMN description TEXT');
    }
  }

  // ====================== DỮ LIỆU MẪU CHO BXH ======================
  // Thêm vài tài khoản mẫu và quan hệ bạn bè để Bảng xếp hạng có dữ liệu xem.
  // Mật khẩu tất cả tài khoản mẫu: Test@123
  Future<void> _seedSampleFriends(Database db) async {
    const extraUsers = [
      ['Lan Anh', 'lan@test.com', 900, 300, 18, 25],
      ['Quốc Bảo', 'bao@test.com', 420, 150, 7, 12],
      ['Hoàng Yến', 'yen@test.com', 180, 60, 3, 9],
    ];
    for (final u in extraUsers) {
      await db.insert('users', {
        'name': u[0],
        'email': u[1],
        'password': 'Test@123',
        'exp': u[2],
        'gold': u[3],
        'currentStreak': u[4],
        'longestStreak': u[5],
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    Future<int?> idOf(String email) async {
      final rows = await db.query(
        'users',
        columns: ['id'],
        where: 'email = ?',
        whereArgs: [email],
      );
      return rows.isEmpty ? null : rows.first['id'] as int;
    }

    Future<void> befriend(String a, String b) async {
      final idA = await idOf(a);
      final idB = await idOf(b);
      if (idA == null || idB == null) return;
      for (final pair in [
        [idA, idB],
        [idB, idA],
      ]) {
        await db.insert('friends', {
          'user_id': pair[0],
          'friend_user_id': pair[1],
          'status': 'accepted',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // Tài (Pro) có đầy đủ bạn bè -> BXH 7 người
    for (final e in [
      'nhat@test.com',
      'thanh@test.com',
      'duc@test.com',
      'lan@test.com',
      'bao@test.com',
      'yen@test.com',
    ]) {
      await befriend('pro@test.com', e);
    }
    // Tài (Newbie) có vài người bạn -> BXH nhỏ, đứng cuối bảng
    await befriend('new@test.com', 'nhat@test.com');
    await befriend('new@test.com', 'thanh@test.com');
    await befriend('new@test.com', 'yen@test.com');
    // Bạn bè chéo giữa các tài khoản mẫu khác
    await befriend('nhat@test.com', 'thanh@test.com');
    await befriend('nhat@test.com', 'lan@test.com');
    await befriend('thanh@test.com', 'duc@test.com');
    await befriend('thanh@test.com', 'lan@test.com');
    await befriend('lan@test.com', 'bao@test.com');

    // 1 lời mời kết bạn đang chờ để demo màn Thông báo của Tài (Newbie)
    final bao = await idOf('bao@test.com');
    final newbie = await idOf('new@test.com');
    if (bao != null && newbie != null) {
      await db.insert('friends', {
        'user_id': bao,
        'friend_user_id': newbie,
        'status': 'pending',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // BXH chuỗi: bản thân + bạn bè đã kết bạn, xếp theo chuỗi hiện tại
  Future<List<UserModel>> getStreakLeaderboard(int userId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT * FROM users
      WHERE id = ?
         OR id IN (SELECT friend_user_id FROM friends
                   WHERE user_id = ? AND status = 'accepted')
      ORDER BY currentStreak DESC, longestStreak DESC, name ASC
    ''',
      [userId, userId],
    );
    return rows.map((r) => UserModel.fromMap(r)).toList();
  }

  // Bảng nhóm, thành viên nhóm và thông báo (version 3)
  Future<void> _createGroupTables(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS work_groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      leader_id INTEGER NOT NULL,
      created_at TEXT,
      FOREIGN KEY (leader_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS group_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      group_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      UNIQUE(group_id, user_id),
      FOREIGN KEY (group_id) REFERENCES work_groups (id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
    await db.execute('''
    CREATE TABLE IF NOT EXISTS notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL,
      message TEXT NOT NULL,
      created_at TEXT,
      is_read INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  Future<void> _createRewardsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS custom_rewards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  String formatDateKey(int day, int month, int year) {
    final dd = day.toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      exp INTEGER DEFAULT 0,
      gold INTEGER DEFAULT 0,
      currentStreak INTEGER DEFAULT 0,
      longestStreak INTEGER DEFAULT 0,
      avatarPath TEXT,
      hp INTEGER DEFAULT ${GameRules.maxHp},
      shields INTEGER DEFAULT 0,
      lastCheckedDate TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      day INTEGER DEFAULT 21,
      month INTEGER DEFAULT 1,
      year INTEGER DEFAULT 2026,
      title TEXT NOT NULL,
      description TEXT,
      time TEXT,
      category TEXT,
      isDaily INTEGER DEFAULT 0,
      isHighPriority INTEGER DEFAULT 0,
      isDone INTEGER DEFAULT 0,
      exp_reward INTEGER DEFAULT 20,
      gold_reward INTEGER DEFAULT 10,
      locationName TEXT,
      reminderEnabled INTEGER DEFAULT 1,
      group_id INTEGER,
      group_name TEXT,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      isDaily INTEGER DEFAULT 0,
      UNIQUE(user_id, name),
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE daily_task_completions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      task_id INTEGER NOT NULL,
      date_key TEXT NOT NULL,
      is_done INTEGER DEFAULT 1,
      UNIQUE(user_id, task_id, date_key),
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE friends (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      friend_user_id INTEGER NOT NULL,
      status TEXT DEFAULT 'accepted',
      UNIQUE(user_id, friend_user_id),
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (friend_user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    await _createRewardsTable(db);
    await _createGroupTables(db);

    await db.execute('''
      INSERT INTO users (name, email, password, exp, gold, currentStreak, longestStreak)
      VALUES ('Tài (Newbie)', 'new@test.com', 'Test@123', 0, 0, 0, 0)
    ''');

    await db.execute('''
      INSERT INTO users (name, email, password, exp, gold, currentStreak, longestStreak)
      VALUES ('Tài (Pro)', 'pro@test.com', 'Test@123', 1500, 500, 15, 21)
    ''');

    await db.execute('''
      INSERT INTO users (name, email, password, exp, gold, currentStreak, longestStreak)
      VALUES ('Minh Nhật', 'nhat@test.com', 'Test@123', 640, 220, 10, 14)
    ''');

    await db.execute('''
      INSERT INTO users (name, email, password, exp, gold, currentStreak, longestStreak)
      VALUES ('Tấn Thành', 'thanh@test.com', 'Test@123', 1120, 400, 22, 22)
    ''');

    await db.execute('''
      INSERT INTO users (name, email, password, exp, gold, currentStreak, longestStreak)
      VALUES ('Đức Nguyễn', 'duc@test.com', 'Test@123', 320, 120, 5, 8)
    ''');

    await _seedSampleFriends(db);
  }

  // ====================== USER LOGIC ======================
  Future<UserModel?> registerUser(UserModel user) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [user.email],
    );
    if (result.isNotEmpty) return null;
    // Tài khoản mới: bắt đầu xét từ hôm nay (đánh dấu hôm qua là đã xét)
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final newUser = user.copyWith(
      lastCheckedDate: formatDateKey(
        yesterday.day,
        yesterday.month,
        yesterday.year,
      ),
    );
    final map = newUser.toMap()..remove('id');
    final id = await db.insert('users', map);
    await getCategories(id);
    return newUser.copyWith(id: id);
  }

  Future<UserModel?> loginUser(String email, String password) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      final user = UserModel.fromMap(maps.first);
      if (user.id != null) {
        await getCategories(user.id!);
      }
      return user;
    }
    return null;
  }

  Future<int> updateUserStats(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<UserModel>> searchUsers(String query, int currentUserId) async {
    final db = await instance.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final maps = await db.query(
        'users',
        where: 'id != ?',
        whereArgs: [currentUserId],
      );
      return maps.map((m) => UserModel.fromMap(m)).toList();
    }
    final maps = await db.query(
      'users',
      where: 'id != ? AND (name LIKE ? OR email LIKE ?)',
      whereArgs: [currentUserId, '%$trimmed%', '%$trimmed%'],
    );
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  // ====================== FRIEND LOGIC ======================
  // Tìm tài khoản theo email chính xác (không phân biệt hoa thường)
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return maps.isEmpty ? null : UserModel.fromMap(maps.first);
  }

  // Trạng thái quan hệ giữa 2 tài khoản:
  // 'friend' | 'sent' (mình đã gửi lời mời) | 'received' (họ đã gửi) | 'none'
  Future<String> getFriendStatus(int userId, int otherId) async {
    final db = await instance.database;
    final mine = await db.query(
      'friends',
      where: 'user_id = ? AND friend_user_id = ?',
      whereArgs: [userId, otherId],
    );
    if (mine.isNotEmpty) {
      return mine.first['status'] == 'accepted' ? 'friend' : 'sent';
    }
    final theirs = await db.query(
      'friends',
      where: 'user_id = ? AND friend_user_id = ? AND status = ?',
      whereArgs: [otherId, userId, 'pending'],
    );
    return theirs.isNotEmpty ? 'received' : 'none';
  }

  // Gửi lời mời kết bạn (người nhận sẽ thấy trong Thông báo)
  Future<bool> sendFriendRequest(int userId, int friendUserId) async {
    if (userId == friendUserId) return false;
    final status = await getFriendStatus(userId, friendUserId);
    if (status == 'received') {
      // Đối phương đã mời mình trước -> kết bạn luôn
      await acceptFriendRequestFrom(friendUserId, userId);
      return true;
    }
    if (status != 'none') return false;
    final db = await instance.database;
    await db.insert('friends', {
      'user_id': userId,
      'friend_user_id': friendUserId,
      'status': 'pending',
    });
    return true;
  }

  // Danh sách lời mời kết bạn gửi đến userId
  Future<List<FriendModel>> getIncomingFriendRequests(int userId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT f.id, f.user_id, f.friend_user_id, f.status,
             u.name, u.email, u.currentStreak
      FROM friends f
      JOIN users u ON u.id = f.user_id
      WHERE f.friend_user_id = ? AND f.status = 'pending'
      ORDER BY f.id DESC
    ''',
      [userId],
    );
    return rows.map((r) => FriendModel.fromMap(r)).toList();
  }

  // Chấp nhận lời mời: senderId đã mời receiverId
  Future<void> acceptFriendRequestFrom(int senderId, int receiverId) async {
    final db = await instance.database;
    await db.update(
      'friends',
      {'status': 'accepted'},
      where: 'user_id = ? AND friend_user_id = ?',
      whereArgs: [senderId, receiverId],
    );
    // Tạo quan hệ chiều ngược lại để cả 2 đều thấy nhau trong danh sách bạn bè
    await db.insert('friends', {
      'user_id': receiverId,
      'friend_user_id': senderId,
      'status': 'accepted',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> declineFriendRequestFrom(int senderId, int receiverId) async {
    final db = await instance.database;
    await db.delete(
      'friends',
      where: 'user_id = ? AND friend_user_id = ? AND status = ?',
      whereArgs: [senderId, receiverId, 'pending'],
    );
  }

  // Hủy kết bạn ở cả 2 chiều
  Future<void> removeFriend(int userId, int friendUserId) async {
    final db = await instance.database;
    await db.delete(
      'friends',
      where:
          '(user_id = ? AND friend_user_id = ?) OR (user_id = ? AND friend_user_id = ?)',
      whereArgs: [userId, friendUserId, friendUserId, userId],
    );
  }

  Future<List<FriendModel>> getFriends(int userId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT f.id, f.user_id, f.friend_user_id, f.status,
             u.name, u.email, u.currentStreak
      FROM friends f
      JOIN users u ON u.id = f.friend_user_id
      WHERE f.user_id = ? AND f.status = 'accepted'
      ORDER BY u.name ASC
    ''',
      [userId],
    );

    return rows.map((r) => FriendModel.fromMap(r)).toList();
  }

  // ====================== TASK LOGIC ======================
  Future<int> insertTask(TaskModel task, int userId) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap(userId));
  }

  Future<int> updateTask(TaskModel task, int userId) async {
    if (task.id == null) return 0;
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(userId),
      where: 'id = ? AND user_id = ?',
      whereArgs: [task.id, userId],
    );
  }

  Future<int> deleteTask(int taskId, int userId) async {
    final db = await instance.database;
    await db.delete(
      'daily_task_completions',
      where: 'task_id = ? AND user_id = ?',
      whereArgs: [taskId, userId],
    );
    return await db.delete(
      'tasks',
      where: 'id = ? AND user_id = ?',
      whereArgs: [taskId, userId],
    );
  }

  Future<List<TaskModel>> getTasks(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => TaskModel.fromMap(map)).toList();
  }

  Future<List<TaskModel>> getTasksForDate(
    int userId,
    int day,
    int month,
    int year,
  ) async {
    final db = await instance.database;
    final dateKey = formatDateKey(day, month, year);

    final rawTasks = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final completionRows = await db.query(
      'daily_task_completions',
      where: 'user_id = ? AND date_key = ?',
      whereArgs: [userId, dateKey],
    );

    final Set<int> completedDailyIds = {
      for (final row in completionRows)
        if ((row['is_done'] ?? 0) == 1 && row['task_id'] != null)
          row['task_id'] as int,
    };

    final List<TaskModel> result = [];
    for (final map in rawTasks) {
      final task = TaskModel.fromMap(map);
      if (task.isDaily) {
        final doneOnThisDay =
            task.id != null && completedDailyIds.contains(task.id);
        result.add(
          task.copyWith(
            day: day,
            month: month,
            year: year,
            isDone: doneOnThisDay,
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
    final db = await instance.database;
    if (task.isDaily && task.id != null) {
      final dateKey = formatDateKey(day, month, year);
      if (isDone) {
        await db.insert('daily_task_completions', {
          'user_id': userId,
          'task_id': task.id,
          'date_key': dateKey,
          'is_done': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await db.delete(
          'daily_task_completions',
          where: 'user_id = ? AND task_id = ? AND date_key = ?',
          whereArgs: [userId, task.id, dateKey],
        );
      }
    } else if (task.id != null) {
      await updateTaskStatus(task.id!, isDone);
    }
  }

  Future<int> updateTaskStatus(int taskId, bool isDone) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {'isDone': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ====================== CATEGORY LOGIC ======================
  Future<List<Map<String, dynamic>>> getCategories(int userId) async {
    final db = await instance.database;
    var maps = await db.query(
      'categories',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) {
      final defaults = [
        {'name': dailyCategoryName, 'isDaily': 1},
        {'name': 'Đại học', 'isDaily': 0},
        {'name': 'Cá nhân', 'isDaily': 0},
        {'name': 'Thể thao', 'isDaily': 0},
        {'name': 'Gia đình', 'isDaily': 0},
      ];
      for (final item in defaults) {
        await db.insert('categories', {
          'user_id': userId,
          'name': item['name'],
          'isDaily': item['isDaily'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      maps = await db.query(
        'categories',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } else {
      final hasDaily = maps.any((c) => c['name'] == dailyCategoryName);
      if (!hasDaily) {
        await db.insert('categories', {
          'user_id': userId,
          'name': dailyCategoryName,
          'isDaily': 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        maps = await db.query(
          'categories',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      }
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
    final db = await instance.database;
    final cleanName = name.trim();
    final dailyFlag = (cleanName == dailyCategoryName || isDaily) ? 1 : 0;
    return await db.insert('categories', {
      'user_id': userId,
      'name': cleanName,
      'isDaily': dailyFlag,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateCategoryAndTasks(
    int userId,
    int categoryId,
    String oldName,
    String newName,
  ) async {
    if (oldName == dailyCategoryName) return;
    final db = await instance.database;
    final cleanNewName = newName.trim();
    await db.update(
      'categories',
      {'name': cleanNewName},
      where: 'id = ? AND user_id = ?',
      whereArgs: [categoryId, userId],
    );
    await db.update(
      'tasks',
      {'category': cleanNewName},
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, oldName],
    );
  }

  Future<void> deleteCategoryAndTasks(
    int userId,
    int categoryId,
    String categoryName,
  ) async {
    if (categoryName == dailyCategoryName) return;
    final db = await instance.database;
    await db.delete(
      'categories',
      where: 'id = ? AND user_id = ?',
      whereArgs: [categoryId, userId],
    );
    await db.update(
      'tasks',
      {'category': 'Khác', 'isDaily': 0},
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, categoryName],
    );
  }

  // ====================== CUSTOM REWARD LOGIC ======================
  Future<List<Map<String, dynamic>>> getCustomRewards(int userId) async {
    final db = await instance.database;
    return await db.query(
      'custom_rewards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  Future<int> insertCustomReward(
    int userId,
    String name,
    String description,
  ) async {
    final db = await instance.database;
    return await db.insert('custom_rewards', {
      'user_id': userId,
      'name': name.trim(),
      'description': description.trim(),
    });
  }

  Future<int> deleteCustomReward(int rewardId, int userId) async {
    final db = await instance.database;
    return await db.delete(
      'custom_rewards',
      where: 'id = ? AND user_id = ?',
      whereArgs: [rewardId, userId],
    );
  }

  // ====================== STATISTICS ======================
  // Tổng số lần hoàn thành: task thường đã xong + mỗi lần hoàn thành task hàng ngày
  Future<int> countCompletedTasks(int userId) async {
    final db = await instance.database;
    final normal = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM tasks WHERE user_id = ? AND isDaily = 0 AND isDone = 1',
        [userId],
      ),
    );
    final daily = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM daily_task_completions WHERE user_id = ? AND is_done = 1',
        [userId],
      ),
    );
    return (normal ?? 0) + (daily ?? 0);
  }

  // ====================== GROUP LOGIC ======================
  // Tạo nhóm: người tạo là nhóm trưởng và tự động là thành viên
  Future<int> createGroup(String name, int leaderId, List<int> memberIds) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final groupId = await txn.insert('work_groups', {
        'name': name.trim(),
        'leader_id': leaderId,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (final uid in {leaderId, ...memberIds}) {
        await txn.insert('group_members', {
          'group_id': groupId,
          'user_id': uid,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return groupId;
    });
  }

  // Các nhóm mà userId đang tham gia
  Future<List<GroupModel>> getGroupsForUser(int userId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT g.id, g.name, g.leader_id, u.name AS leader_name,
             (SELECT COUNT(*) FROM group_members m2 WHERE m2.group_id = g.id) AS member_count
      FROM work_groups g
      JOIN group_members m ON m.group_id = g.id
      JOIN users u ON u.id = g.leader_id
      WHERE m.user_id = ?
      ORDER BY g.id DESC
    ''',
      [userId],
    );
    return rows.map((r) => GroupModel.fromMap(r)).toList();
  }

  Future<List<UserModel>> getGroupMembers(int groupId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT u.* FROM group_members m
      JOIN users u ON u.id = m.user_id
      WHERE m.group_id = ?
      ORDER BY u.name ASC
    ''',
      [groupId],
    );
    return rows.map((r) => UserModel.fromMap(r)).toList();
  }

  Future<void> removeGroupMember(int groupId, int userId) async {
    final db = await instance.database;
    await db.delete(
      'group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<GroupModel?> getGroupById(int groupId) async {
    final db = await instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT g.id, g.name, g.leader_id, u.name AS leader_name,
             (SELECT COUNT(*) FROM group_members m WHERE m.group_id = g.id) AS member_count
      FROM work_groups g
      JOIN users u ON u.id = g.leader_id
      WHERE g.id = ?
    ''',
      [groupId],
    );
    return rows.isEmpty ? null : GroupModel.fromMap(rows.first);
  }

  // Danh sách việc đã giao trong nhóm, kèm tên người đảm nhận (cột assignee_name)
  Future<List<Map<String, dynamic>>> getGroupTasks(int groupId) async {
    final db = await instance.database;
    return await db.rawQuery(
      '''
      SELECT t.*, u.name AS assignee_name
      FROM tasks t
      JOIN users u ON u.id = t.user_id
      WHERE t.group_id = ?
      ORDER BY t.year DESC, t.month DESC, t.day DESC, t.time ASC
    ''',
      [groupId],
    );
  }

  Future<void> _notifyAssignee({
    required int assigneeId,
    required String leaderName,
    required String groupName,
    required String taskTitle,
  }) async {
    final db = await instance.database;
    await db.insert('notifications', {
      'user_id': assigneeId,
      'type': 'task_assigned',
      'message':
          '$leaderName (nhóm trưởng "$groupName") đã giao cho bạn: "$taskTitle"',
      'created_at': DateTime.now().toIso8601String(),
      'is_read': 0,
    });
  }

  // Nhóm trưởng giao việc: tạo task cho người đảm nhận
  // và gửi thông báo nếu người đảm nhận không phải nhóm trưởng
  Future<int> assignGroupTask({
    required GroupModel group,
    required int leaderId,
    required String leaderName,
    required int assigneeId,
    required TaskModel task,
  }) async {
    final db = await instance.database;
    final groupTask = task.copyWith(
      category: groupCategoryName,
      isDaily: false,
      groupId: group.id,
      groupName: group.name,
    );
    final id = await db.insert('tasks', groupTask.toMap(assigneeId));
    if (assigneeId != leaderId) {
      await _notifyAssignee(
        assigneeId: assigneeId,
        leaderName: leaderName,
        groupName: group.name,
        taskTitle: groupTask.title,
      );
    }
    return id;
  }

  // Nhóm trưởng sửa việc nhóm (có thể đổi người đảm nhận)
  Future<void> updateGroupTask({
    required GroupModel group,
    required int leaderId,
    required String leaderName,
    required int oldAssigneeId,
    required int newAssigneeId,
    required TaskModel task,
  }) async {
    if (task.id == null) return;
    final db = await instance.database;
    final groupTask = task.copyWith(
      category: groupCategoryName,
      isDaily: false,
      groupId: group.id,
      groupName: group.name,
    );
    await db.update(
      'tasks',
      groupTask.toMap(newAssigneeId),
      where: 'id = ? AND group_id = ?',
      whereArgs: [task.id, group.id],
    );
    if (newAssigneeId != oldAssigneeId && newAssigneeId != leaderId) {
      await _notifyAssignee(
        assigneeId: newAssigneeId,
        leaderName: leaderName,
        groupName: group.name,
        taskTitle: groupTask.title,
      );
    }
  }

  // Nhóm trưởng xóa việc nhóm (không phụ thuộc người đảm nhận)
  Future<void> deleteGroupTask(int taskId) async {
    final db = await instance.database;
    await db.delete(
      'daily_task_completions',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // ====================== NOTIFICATION LOGIC ======================
  Future<List<NotificationModel>> getNotifications(int userId) async {
    final db = await instance.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map((r) => NotificationModel.fromMap(r)).toList();
  }

  Future<void> markAllNotificationsRead(int userId) async {
    final db = await instance.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );
  }

  // Số mục chưa xem = thông báo chưa đọc + lời mời kết bạn đang chờ
  Future<int> countUnseen(int userId) async {
    final db = await instance.database;
    final unread = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0',
        [userId],
      ),
    );
    final requests = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM friends WHERE friend_user_id = ? AND status = 'pending'",
        [userId],
      ),
    );
    return (unread ?? 0) + (requests ?? 0);
  }
}
