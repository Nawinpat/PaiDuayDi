import 'package:flutter_test/flutter_test.dart';
import 'package:paiduaydi/main.dart';

void main() {
  testWidgets('App loads splash screen and transitions to auth entry', (WidgetTester tester) async {
    await tester.pumpWidget(const PaiDuayDiApp());
    expect(find.text('PaiDuayDi'), findsOneWidget);
    
    // Advance timer to trigger transition to AuthEntryScreen
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('ดำเนินการต่อด้วย Facebook'), findsOneWidget);
    expect(find.text('ดำเนินการต่อด้วย Google'), findsOneWidget);
  });
}
