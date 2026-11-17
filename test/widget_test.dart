import 'package:flatmate_app/app.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlatmateApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Flatmate App'), findsOneWidget);
  });
}
