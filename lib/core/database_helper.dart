import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/friend_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String dailyCategoryName = 'Hàng ngày';

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gamification_app_v7.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
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
      avatarPath TEXT
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
      time TEXT,
      category TEXT,
      isDaily INTEGER DEFAULT 0,
      isHighPriority INTEGER DEFAULT 0,
      isDone INTEGER DEFAULT 0,
      exp_reward INTEGER DEFAULT 20,
      gold_reward INTEGER DEFAULT 10,
      locationName TEXT,
      reminderEnabled INTEGER DEFAULT 1,
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
    final id = await db.insert('users', user.toMap());
    await getCategories(id);
    return UserModel(
      id: id,
      name: user.name,
      email: user.email,
      password: user.password,
    );
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
  Future<bool> addFriend(int userId, int friendUserId) async {
    if (userId == friendUserId) return false;
    final db = await instance.database;
    final existing = await db.query(
      'friends',
      where: 'user_id = ? AND friend_user_id = ?',
      whereArgs: [userId, friendUserId],
    );
    if (existing.isNotEmpty) return false;

    await db.insert('friends', {
      'user_id': userId,
      'friend_user_id': friendUserId,
      'status': 'accepted',
    });
    return true;
  }

  Future<void> removeFriend(int userId, int friendUserId) async {
    final db = await instance.database;
    await db.delete(
      'friends',
      where: 'user_id = ? AND friend_user_id = ?',
      whereArgs: [userId, friendUserId],
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
      WHERE f.user_id = ?
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
}
