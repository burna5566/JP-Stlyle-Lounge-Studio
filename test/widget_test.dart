// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:jp_style_lounge_studio/main.dart';

void main() {
  testWidgets('shows booking flow shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      const JpStyleLoungeStudioApp(appwriteConfigValid: false),
    );

    expect(find.text('JP Style Lounge Studio'), findsOneWidget);
    expect(find.text('Book Appointment'), findsOneWidget);
    expect(
      find.textContaining('Runtime config status: INVALID'),
      findsOneWidget,
    );
    expect(find.text('Choose service'), findsOneWidget);
  });
}
