import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_balance/MotionBalanceApp/motion_balance_app.dart';

void main() {
  testWidgets('MotionBalanceApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MotionBalanceApp(),
      ),
    );

    expect(find.byType(MotionBalanceApp), findsOneWidget);
  });
}
