// Basic Flutter widget test for Hostel App

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hostel_app/main.dart';
import 'package:hostel_app/providers/student_provider.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HostelApp());

    // Verify that the app loaded with the title
    expect(find.text('HostelMS'), findsOneWidget);
  });
}
