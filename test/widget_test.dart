// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memeboard/main.dart';

void main() {
  testWidgets('MemeBoard smoke test - shows app title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemeBoardApp());

    // Verify the splash screen title/text is present.
    expect(find.text('MemeBoard'), findsOneWidget);
  });
}
