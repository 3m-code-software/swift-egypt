import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/app.dart';

void main() {
  testWidgets('App should display splash screen on start',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DriverApp());

    expect(find.text('Swift Egypt'), findsOneWidget);
    expect(find.text('تطبيق السائقين'), findsOneWidget);
  });
}
