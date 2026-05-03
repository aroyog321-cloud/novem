import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../lib/screens/editor_screen.dart';

void main() {
  testWidgets('EditorScreen build test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: EditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EditorScreen), findsOneWidget);
  });
}
