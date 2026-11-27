import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management_app/core/app_session.dart';
import 'package:task_management_app/models/user_model.dart';
import 'package:task_management_app/view_models/gamification_view_model.dart';
import 'package:task_management_app/views/shop/shop_view.dart';
import 'package:task_management_app/views/streak/streak_view.dart';
import 'package:task_management_app/views/pet/pet_view.dart';
import 'package:task_management_app/views/leaderboard/leaderboard_view.dart';

void main() {
  testWidgets(
    'account balance, inventory, streak and local rank render from the same model',
    (tester) async {
      final game = GamificationViewModel();
      AppSession.currentUser = UserModel(
        id: 7,
        name: 'Linh',
        email: 'test@example.test',
        password: 'test',
        gold: 37,
        currentStreak: 10,
        freezes: 2,
      );
      game.activeToday = true;
      game.inventory = {'hat': true};
      game.ranking = [
        {'id': 7, 'name': 'Linh', 'currentStreak': 10},
      ];
      Future<void> open(Widget screen) async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: game,
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pump();
      }

      await open(const ShopView());
      expect(find.text('37 Vàng'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có giao dịch'), findsOneWidget);
      Navigator.of(tester.element(find.text('Chưa có giao dịch'))).pop();
      await tester.pumpAndSettle();
      await open(const PetView());
      expect(
        (tester.widget<Image>(find.byType(Image)).image as AssetImage)
            .assetName,
        endsWith('lv2_hat.png'),
      );
      await open(const StreakView());
      expect(find.text('10 ngày'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      await open(const LeaderboardView());
      expect(find.text('Linh (Bạn)'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      AppSession.currentUser = null;
      game.dispose();
    },
  );
}
