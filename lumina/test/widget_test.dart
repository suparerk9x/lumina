import 'package:flutter_test/flutter_test.dart';

import 'package:lumina/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DemenishApp());

    expect(find.text('ฝึกสมอง'), findsWidgets);
    expect(find.text('ประเมิน'), findsOneWidget);
    expect(find.text('จำกัดเวลา'), findsOneWidget);
  });
}
