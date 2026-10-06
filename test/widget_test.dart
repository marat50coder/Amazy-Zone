// Smoke test for Amazy Zone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amazy_zone/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const AmazyZoneApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
