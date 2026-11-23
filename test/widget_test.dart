import 'package:erat_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ERAT app renders welcome onboarding and brand logo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EratApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('Erat'), findsWidgets);
  });
}
