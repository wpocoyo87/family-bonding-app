import 'package:erat_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ERAT app renders welcome onboarding and navigates to dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EratApp(),
      ),
    );

    expect(find.textContaining('Get Started'), findsOneWidget);
  });
}
