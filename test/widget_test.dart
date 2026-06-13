import 'package:flutter_test/flutter_test.dart';
import 'package:suray_aio/app/app.dart';

void main() {
  testWidgets('SurayApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const SurayApp());
    expect(find.text('Calculadora de Talonarios'), findsOneWidget);
  });
}
