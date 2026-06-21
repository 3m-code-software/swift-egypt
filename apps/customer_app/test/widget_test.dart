import 'package:flutter_test/flutter_test.dart';
import 'package:swift_egypt/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SwiftEgyptApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
