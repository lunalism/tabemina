// Basic smoke test for Tabemina.
//
// The full app requires Firebase and Google Maps platform channels that are
// not available in a plain widget test, so this verifies a representative
// screen builds rather than pumping the whole app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tabemina/features/search/presentation/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen renders its title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SearchScreen()),
      ),
    );

    expect(find.text('Search Screen'), findsOneWidget);
  });
}
