import 'package:flutter_test/flutter_test.dart';
import 'package:shuangtang_app/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DoubleSugarApp());
    expect(find.text('双糖'), findsOneWidget);
    expect(find.text('两颗心，双倍糖。'), findsOneWidget);
  });
}
