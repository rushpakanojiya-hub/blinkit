// Basic smoke test: verifies the app builds without throwing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gofresh_customer/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
  });
}
