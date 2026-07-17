import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mykirana/app.dart';

void main() {
  testWidgets('App launches and shows phone input screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
