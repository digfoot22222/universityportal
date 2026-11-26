import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:university_portal_enterprise/main.dart';

void main() {
  testWidgets('UniCore SaaS Portal boots cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UniversityPortalApp()));
    await tester.pumpAndSettle();
    expect(find.text('UniCore SaaS Campus OS'), findsOneWidget);
  });
}