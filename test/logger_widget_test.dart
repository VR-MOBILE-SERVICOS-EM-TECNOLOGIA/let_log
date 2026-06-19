import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:let_log/let_log.dart';

Future<void> pumpLogger(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Logger()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(Logger.clear);

  testWidgets('Log and Net tabs render; log message visible', (tester) async {
    Logger.log('t', 'my log line');
    await pumpLogger(tester);
    // "Log" and "Net" appear in the tab bar (may appear >1 due to render tree)
    expect(find.text('Log'), findsWidgets);
    expect(find.text('Net'), findsWidgets);
    expect(find.text('my log line'), findsOneWidget);
  });

  testWidgets('Switch to Net tab shows net api', (tester) async {
    Logger.net('api/abc', data: {'k': 1});
    await pumpLogger(tester);
    await tester.tap(find.text('Net'));
    await tester.pumpAndSettle();
    expect(find.text('api/abc'), findsOneWidget);
  });

  testWidgets('Error badge shows count on Net tab', (tester) async {
    Logger.net('api/err');
    Logger.endNet('api/err', status: 500);
    await pumpLogger(tester);
    // The _ErrorBadge shows the count as text inside the Net tab
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Empty state shows correct message on Log tab', (tester) async {
    await pumpLogger(tester);
    expect(find.text('Nenhum log capturado ainda.'), findsOneWidget);
  });

  testWidgets('Search filter shows matching log and hides non-matching', (
    tester,
  ) async {
    Logger.log('t', 'alpha one');
    Logger.log('t', 'beta two');
    await pumpLogger(tester);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pumpAndSettle();
    expect(find.text('alpha one'), findsOneWidget);
    expect(find.text('beta two'), findsNothing);
  });

  testWidgets('Expand net detail shows GENERAL section', (tester) async {
    Logger.net('api/detail', data: {'x': 1});
    Logger.endNet('api/detail', data: {'y': 2});
    await pumpLogger(tester);
    await tester.tap(find.text('Net'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('api/detail'));
    await tester.pumpAndSettle();
    expect(find.text('GENERAL'), findsOneWidget);
  });

  testWidgets('Theme toggle switches between dark and light icons', (
    tester,
  ) async {
    await pumpLogger(tester);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}
