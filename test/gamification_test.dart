import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_management_app/core/app_session.dart';
import 'package:task_management_app/core/database_helper.dart';
import 'package:task_management_app/models/pet_model.dart';
import 'package:task_management_app/models/shop_item_model.dart';
import 'package:task_management_app/models/task_model.dart';
import 'package:task_management_app/models/user_model.dart';
import 'package:task_management_app/services/game_store.dart';
import 'package:task_management_app/services/shared_tasks.dart';
import 'package:task_management_app/view_models/gamification_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final helper = DatabaseHelper.instance;
  late Directory dir;
  late Database db;
  late int id;
  final now = DateTime.now();
  DateTime day(int offset) =>
      DateTime(now.year, now.month, now.day + offset, 12);
  Future<UserModel> register(String name) async => (await helper.registerUser(
    UserModel(name: name, email: '$name@example.test', password: 'Test123!'),
  ))!;
  Future<int> task({
    int offset = 0,
    bool daily = false,
    int exp = 40,
    int gold = 20,
    String time = '23:59',
  }) => helper.insertTask(
    TaskModel(
      title: 'Task',
      category: 'Test',
      year: day(offset).year,
      month: day(offset).month,
      day: day(offset).day,
      time: time,
      isDaily: daily,
      exp: exp,
      gold: gold,
    ),
    id,
  );
  Future<Map<String, Object?>> profile() async =>
      (await db.query('users', where: 'id=?', whereArgs: [id])).single;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await Directory('build').create(recursive: true);
    dir = await Directory('build').createTemp('game-db-');
    await databaseFactory.setDatabasesPath(dir.absolute.path);
  });
  setUp(() async {
    db = await helper.database;
    AppSession.currentUser = await register(
      'test${DateTime.now().microsecondsSinceEpoch}',
    );
    id = AppSession.currentUser!.id!;
  });
  tearDownAll(() async {
    await (await helper.database).close();
    await dir.delete(recursive: true);
  });

  test('repeated taps, late completion, undo and reopen keep one reward and one penalty', () async {
    final t = await task(offset: -1, exp: 245, gold: 33);
    expect(
      await Future.wait(
        List.generate(2, (_) => GameStore.complete(db, id, t, true, now)),
      ),
      containsAll([true, false]),
    );
    await GameStore.complete(db, id, t, false, now);
    expect(await GameStore.complete(db, id, t, true, now), false);
    final p = await profile();
    expect(
      [p['exp'], p['gold'], p['hp'], p['currentStreak']],
      [245, 33, 95, 1],
    );
    final saved = (await helper.getTasks(id)).single;
    await helper.updateTask(saved.copyWith(title: 'Edited', exp: 500), id);
    await helper.deleteTask(t, id);
    expect(await GameStore.complete(db, id, t, true, now), false);
    final email = AppSession.currentUser!.email;
    AppSession.currentUser = null;
    await db.close();
    db = await helper.database;
    expect((await helper.loginUser(email, 'Test123!'))!.gold, 33);
    expect(
      (await db.query('events', where: 'user_id=?', whereArgs: [id])).length,
      2,
    );
  });
  test(
    'calendar dates, missed days, shield use and longest streak across year',
    () async {
      final start = DateTime(2025, 12, 31, 10);
      final t = await helper.insertTask(
        TaskModel(
          title: 'Daily',
          category: 'Test',
          isDaily: true,
          year: 2025,
          month: 12,
          day: 31,
          time: '23:59',
        ),
        id,
      );
      final second = await helper.insertTask(
        TaskModel(
          title: 'Other',
          category: 'Test',
          year: 2025,
          month: 12,
          day: 31,
          time: '23:59',
        ),
        id,
      );
      await db.update('users', {'freezes': 1}, where: 'id=?', whereArgs: [id]);
      await GameStore.complete(db, id, t, true, start);
      await GameStore.complete(db, id, second, true, start);
      expect((await profile())['currentStreak'], 1);
      await GameStore.complete(db, id, t, true, DateTime(2026, 1, 1, 10));
      await GameStore.complete(db, id, t, true, DateTime(2026, 1, 3, 10));
      await db.transaction(
        (tx) => GameStore.reconcile(tx, id, DateTime(2026, 1, 3, 11)),
      );
      final p = await profile();
      expect(
        [p['currentStreak'], p['longestStreak'], p['freezes'], p['hp']],
        [3, 3, 0, 95],
      );
      expect(
        (await helper.getTasksForDate(id, 3, 1, 2026)).single.isDone,
        true,
      );
      await db.transaction(
        (tx) => GameStore.reconcile(tx, id, DateTime(2026, 1, 6, 10)),
      );
      final expired = await profile();
      expect(
        [expired['currentStreak'], expired['longestStreak'], expired['hp']],
        [0, 3, 85],
      );
    },
  );
  test('purchases, retry receipts, custom CRUD, equipment, reports and account isolation', () async {
    final game = GamificationViewModel();
    await game.refresh();
    expect(game.total, 0);
    final hat = ShopItemModel.catalog.firstWhere((i) => i.slot == 'hat');
    expect(await game.buy(hat, 'poor'), isNotNull);
    await game.equip('hat', true);
    expect(game.inventory, isEmpty);
    final daily = await task(offset: -9, daily: true, gold: 100);
    for (var d = -9; d <= 0; d++) {
      await GameStore.complete(db, id, daily, true, day(d));
    }
    await game.refresh();
    expect(game.completedSince(GameStore.date(day(-6))), 7);
    expect(game.completedSince(GameStore.date(day(-29))), 10);
    expect([game.total, game.done, game.overdue], [10, 10, 0]);
    expect(await game.buy(hat, 'hat'), null);
    expect(await game.buy(hat, 'new-receipt'), isNotNull);
    await game.equip('hat', true);
    expect(game.inventory['hat'], true);
    expect(PetModel.asset(10, true, game.inventory), endsWith('lv2_hat.png'));
    await game.equip('hat', false);
    expect(game.inventory['hat'], false);
    await game.saveReward(null, 'Tea', 'Break', 30, 'Cá nhân');
    await game.saveReward(
      game.custom.single.id,
      'Lunch',
      'Break',
      55,
      'Cá nhân',
    );
    expect(await game.buy(game.custom.single, 'lunch'), null);
    expect(await game.buy(game.custom.single, 'lunch'), isNotNull);
    await game.deleteReward(game.custom.single.id!);
    expect(game.custom, isEmpty);
    final freeze = ShopItemModel.catalog.firstWhere((i) => i.slot == 'freeze');
    expect(await game.buy(freeze, 'shield'), null);
    expect(AppSession.currentUser!.freezes, 1);
    expect(AppSession.currentUser!.gold, 625);
    expect(game.events.where((e) => e['kind'] == 'purchase').length, 3);
    final friend = await register('friend'),
        stranger = await register('stranger');
    expect(await SharedTasks.assign(id, friend.id!, 'Group'), false);
    await helper.addFriend(id, friend.id!);
    expect(await SharedTasks.assign(id, friend.id!, 'Group'), true);
    final shared = (await SharedTasks.list(friend.id!)).single;
    expect(
      await SharedTasks.setDone(stranger.id!, shared['id'] as int, true),
      false,
    );
    expect(
      await SharedTasks.setDone(friend.id!, shared['id'] as int, true),
      true,
    );
    expect(await SharedTasks.list(stranger.id!), isEmpty);
    expect((await SharedTasks.list(id)).single['done'], 1);
    await game.refresh();
    expect(game.ranking.map((r) => r['id']), [id, friend.id]);
    AppSession.currentUser = friend;
    await game.refresh();
    expect(game.inventory, isEmpty);
    expect(game.events, isEmpty);
    expect(game.total, 0);
    expect(await GameStore.complete(db, friend.id!, daily, true, now), false);
  });
  test('undo after the daily deadline applies a single penalty and freezes the pet', () async {
    final t = await task(daily: true, time: '10:00');
    final morning = DateTime(now.year, now.month, now.day, 9);
    final noon = DateTime(now.year, now.month, now.day, 12);
    await GameStore.complete(db, id, t, true, morning);
    await GameStore.complete(db, id, t, false, noon);
    await GameStore.complete(db, id, t, false, noon);
    final game = GamificationViewModel();
    await game.refresh();
    expect(game.activeToday, false);
    expect((await profile())['hp'], 95);
    expect(await GameStore.complete(db, id, t, true, noon), false);
    await game.refresh();
    expect(game.activeToday, true);
  });
  test('offline catch-up stops at zero HP and a newly bought shield cannot repair an expired streak', () async {
    final t = await task(offset: -25, daily: true, gold: 150);
    await GameStore.complete(db, id, t, true, day(-25));
    final game = GamificationViewModel();
    await game.refresh();
    expect(AppSession.currentUser!.hp, 0);
    expect(AppSession.currentUser!.currentStreak, 0);
    expect(game.events.fold<int>(0, (n, e) => n + (e['hp'] as int)), -100);
    final count = game.events.where((e) => e['kind'] == 'penalty').length;
    expect(count, greaterThanOrEqualTo(24));
    final shield = ShopItemModel.catalog.singleWhere((i) => i.slot == 'freeze');
    expect(await game.buy(shield, 'after-gap'), isNull);
    await game.refresh();
    expect(AppSession.currentUser!.freezes, 1);
    expect(game.events.where((e) => e['kind'] == 'penalty').length, count);
  });

  test('all pet states use existing assets', () {
    for (final streak in [0, 1, 9, 10]) {
      for (final active in [false, true]) {
        for (var mask = 0; mask < 8; mask++) {
          expect(
            File(
              PetModel.asset(streak, active, {
                'hat': mask.isOdd,
                'glasses': (mask & 2) != 0,
                'shirt': (mask & 4) != 0,
              }),
            ).existsSync(),
            true,
          );
        }
      }
    }
  });
  test('v1 migration preserves balances and prevents re-awarding historical completions', () async {
    final path = '${dir.path}/legacy.db';
    final legacy = await openDatabase(
      path,
      version: 1,
      onCreate: (tx, _) async {
        await tx.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY,exp INTEGER,gold INTEGER,longestStreak INTEGER,currentStreak INTEGER)',
        );
        await tx.execute(
          'CREATE TABLE tasks(id INTEGER PRIMARY KEY,user_id INTEGER,isDaily INTEGER,isDone INTEGER,title TEXT)',
        );
        await tx.execute(
          'CREATE TABLE daily_task_completions(task_id INTEGER,user_id INTEGER,date_key TEXT,is_done INTEGER)',
        );
        await tx.execute("INSERT INTO users VALUES(1,111,77,3,2)");
        await tx.execute(
          "INSERT INTO tasks VALUES(1,1,0,1,'Old'),(2,1,1,0,'Daily')",
        );
        await tx.execute(
          "INSERT INTO daily_task_completions VALUES(2,1,'2026-01-01',1)",
        );
      },
    );
    await legacy.close();
    final migrated = await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, _, _) => GameStore.migrate(db),
    );
    final p = (await migrated.query('users')).single;
    expect(
      [p['exp'], p['gold'], p['hp'], p['longestStreak']],
      [111, 77, 100, 3],
    );
    expect(
      (await migrated.query('events')).map((r) => r['occurrence']),
      containsAll(['1', '2/2026-01-01']),
    );
    expect((await migrated.query('tasks')).length, 2);
    await migrated.close();
  });
}
