import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collegehub/app.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Load your actual root app widget
    await tester.pumpWidget(const CollegeResourceHubApp());

    // Basic sanity check to ensure MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
