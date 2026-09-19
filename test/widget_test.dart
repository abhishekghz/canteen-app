import 'package:canteen_app/app.dart';
import 'package:canteen_app/data/backend.dart';
import 'package:canteen_app/data/memory/seed.dart';
import 'package:canteen_app/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget boot(AppRepositories repos) => ProviderScope(
        overrides: [repositoriesProvider.overrideWithValue(repos)],
        child: const CanteenApp(),
      );

  testWidgets('unauthenticated app shows login', (tester) async {
    await tester.pumpWidget(boot(AppRepositories.memory()));
    await tester.pumpAndSettle();
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Canteen'), findsWidgets);
  });

  testWidgets('admin login lands on admin dashboard', (tester) async {
    final repos = AppRepositories.memory();
    await tester.pumpWidget(boot(repos));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), kSeedAdminEmail);
    await tester.enterText(
        find.byType(TextFormField).at(1), kSeedAdminPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('student login lands on student home', (tester) async {
    final repos = AppRepositories.memory();
    await tester.pumpWidget(boot(repos));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).at(0), kSeedStudentEmail);
    await tester.enterText(
        find.byType(TextFormField).at(1), kSeedStudentPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsWidgets);
  });
}
