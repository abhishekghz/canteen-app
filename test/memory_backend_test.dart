import 'package:canteen_app/data/backend.dart';
import 'package:canteen_app/data/memory/seed.dart';
import 'package:canteen_app/domain/entities/app_user.dart';
import 'package:canteen_app/domain/entities/menu_day.dart';
import 'package:canteen_app/domain/entities/order.dart';
import 'package:canteen_app/domain/repositories/repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded admin can sign in with admin role', () async {
    final repos = AppRepositories.memory();
    final user = await repos.auth.signIn(kSeedAdminEmail, kSeedAdminPassword);
    expect(user.role, UserRole.admin);
  });

  test('register then order round-trips for that user', () async {
    final repos = AppRepositories.memory();
    final student =
        await repos.auth.register('Riya', 'riya@example.com', 'secret1');
    expect(student.role, UserRole.student);

    final draft = Order(
      id: '',
      uid: student.uid,
      createdAt: DateTime.now(),
      lines: const [
        MealLine(
            mealType: MealType.lunch,
            date: '2026-01-01',
            extraRoti: 2,
            packed: true,
            lineTotal: 0), // will be recomputed authoritatively
      ],
      total: 0,
      paymentStatus: PaymentStatus.paid,
    );
    final placed = await repos.orders.place(draft);
    // 5000 base + 2*500 roti + 1500 packing = 7500
    expect(placed.total, 7500);
    expect(placed.paymentStatus, PaymentStatus.paid);

    final orders = await repos.orders.watchForUser(student.uid).first;
    expect(orders.length, 1);
    expect(orders.first.total, 7500);
  });

  test('duplicate email registration fails', () async {
    final repos = AppRepositories.memory();
    await repos.auth.register('A', 'dup@example.com', 'secret1');
    expect(
      () => repos.auth.register('B', 'dup@example.com', 'secret1'),
      throwsA(isA<AuthException>()),
    );
  });

  test('wrong password fails', () async {
    final repos = AppRepositories.memory();
    expect(
      () => repos.auth.signIn(kSeedAdminEmail, 'wrong'),
      throwsA(isA<AuthException>()),
    );
  });

  test('admin sets payment status, student sees it', () async {
    final repos = AppRepositories.memory();
    final s = await repos.auth.register('S', 's@example.com', 'secret1');
    final placed = await repos.orders.place(Order(
      id: '',
      uid: s.uid,
      createdAt: DateTime.now(),
      lines: const [
        MealLine(mealType: MealType.dinner, date: '2026-01-01', lineTotal: 0)
      ],
      total: 0,
    ));
    await repos.orders.setPaymentStatus(placed.id, PaymentStatus.paid);
    final orders = await repos.orders.watchForUser(s.uid).first;
    expect(orders.first.paymentStatus, PaymentStatus.paid);
  });

  test('buy coupons then redeem one', () async {
    final repos = AppRepositories.memory();
    final s = await repos.auth.register('C', 'c@example.com', 'secret1');
    final bought = await repos.coupons.buy(s.uid, MealType.lunch, 3);
    expect(bought.length, 3);
    await repos.coupons.redeem(bought.first.id);
    final mine = await repos.coupons.watchForUser(s.uid).first;
    final redeemed =
        mine.where((c) => c.status.name == 'redeemed').toList();
    expect(redeemed.length, 1);
  });

  test('seed week has 7 days', () async {
    final repos = AppRepositories.memory();
    final week = await repos.menu.watchWeek().first;
    expect(week.length, 7);
    expect(week.map((d) => d.weekday).toSet(), kWeekdays.toSet());
  });
}
