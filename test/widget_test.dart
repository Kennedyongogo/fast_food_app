// This is a basic Flutter widget test for our FastFood app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastfood_app/main.dart';

void main() {
  testWidgets('FastFood app menu loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FastFoodApp());

    // Verify that menu items are displayed
    expect(find.text('🍔 Beef Burger'), findsOneWidget);
    expect(find.text('🍕 Pepperoni Pizza'), findsOneWidget);
    expect(find.text('🍟 French Fries'), findsOneWidget);
  });
}
