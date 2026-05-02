import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nove_mobile/main.dart';

void main() {
  testWidgets('Home screen loads test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NoveApp()));

    // Verify that the app title is displayed.
    expect(find.text('NOVE'), findsOneWidget);
    expect(find.text('PREMIUM WORKSPACE'), findsOneWidget);
  });
}
