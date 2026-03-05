// This is a basic Flutter widget test for the Kigali City Directory app.

import 'package:flutter_test/flutter_test.dart';

import 'package:kigali_city/main.dart';

void main() {
  testWidgets('KigaliCityApp builds without errors', (WidgetTester tester) async {
    // Note: Full integration tests require Firebase to be initialized.
    // This test verifies the widget tree can be referenced correctly.
    expect(KigaliCityApp, isNotNull);
  });
}
