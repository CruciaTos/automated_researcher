// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uiux/app/app.dart';
import 'package:uiux/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('App boots to login screen (smoke test)',
      (WidgetTester tester) async {
    // This app's entrypoint (`main.dart`) wires up Firebase + SharedPreferences
    // before calling runApp(). In a widget test we only need to verify that
    // the UI can build, so we pump the root App wrapped in a ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Let go_router build the initial route.
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
