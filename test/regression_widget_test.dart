import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:let_log/let_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(Logger.clear);

  // Bug (PR #1, Wlad): opening the edit dialog for a text-typed pref and
  // tapping "Cancelar" threw a framework assertion (controller disposed while
  // the dialog was still mounted).
  testWidgets('Prefs: cancelling the edit dialog does not throw', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'username': 'yung'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(MaterialApp(home: Logger(sheredPrefs: prefs)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prefs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('username'));
    await tester.pumpAndSettle();

    expect(find.text('Cancelar'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // Bug (PR #1, Wlad): clearing the Log list did not refresh the header
  // totalizers until the user switched tabs and came back.
  testWidgets('Log totalizer updates to 0 when the list is cleared', (
    tester,
  ) async {
    Logger.log('t', 'one');
    Logger.log('t', 'two');
    await tester.pumpWidget(const MaterialApp(home: Logger()));
    await tester.pumpAndSettle();

    expect(find.text('2 logs'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar logs'));
    await tester.pumpAndSettle();

    expect(find.text('0 logs'), findsOneWidget);
  });

  // Bug (PR #1, Wlad): clearing the Net list left the requests totalizer
  // stale because the toolbar only listened to the types notifier.
  testWidgets('Net totalizer updates to 0 when the list is cleared', (
    tester,
  ) async {
    Logger.net('api/a');
    Logger.net('api/b', type: 'Socket');
    await tester.pumpWidget(const MaterialApp(home: Logger()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Net'));
    await tester.pumpAndSettle();

    expect(find.text('2 requests'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar requisições'));
    await tester.pumpAndSettle();

    expect(find.text('0 requests'), findsOneWidget);
  });
}
