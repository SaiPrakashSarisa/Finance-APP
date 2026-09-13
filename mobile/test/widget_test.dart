import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app_mobile/main.dart';

void main() {
  testWidgets('FinanceApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanceApp()));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(FinanceApp), findsOneWidget);
  });
}
