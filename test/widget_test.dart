import 'package:flutter_test/flutter_test.dart';

import 'package:hostel_management/app.dart';

void main() {
  testWidgets('App renders Hostel Management text',
      (WidgetTester tester) async {
    await tester.pumpWidget(const HostelManagementApp());
    // pumpAndSettle lets GoRouter complete its initial navigation to HomePage.
    await tester.pumpAndSettle();

    expect(find.text('Hostel Management'), findsOneWidget);
  });
}
