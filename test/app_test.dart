import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_expenses_app/main.dart';

void main() {
  testWidgets('App opens the shared expenses start screen', (tester) async {
    await tester.pumpWidget(const SharedExpensesApp());

    expect(find.text('Спільні витрати'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
