import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan/ph/ui/button.dart';

void main() {
  testWidgets('MyButton draws its enabled and disabled gradients', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MyButton(text: 'Enabled'),
              MyButton(text: 'Disabled', enabled: false),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Enabled'), findsOneWidget);
    // The disabled arm paints the grey gradient instead of the red one.
    expect(find.text('Disabled'), findsOneWidget);
  });
}
