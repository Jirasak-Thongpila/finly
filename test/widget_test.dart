import 'package:flutter_test/flutter_test.dart';

import 'package:finly/main.dart';
import 'package:finly/screens/welcome_screen.dart';
import 'package:finly/services/session_manager.dart';
import 'package:finly/utils/storage.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, SessionManager session) async {
    await session.restore();
    await tester.pumpWidget(FinlyApp(session: session));
    await tester.pump(const Duration(seconds: 1));
  }

  SessionManager testSession() => SessionManager(storage: MemoryTokenStorage());

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('unauthenticated session shows the welcome screen',
      (WidgetTester tester) async {
    final session = testSession();
    await pumpApp(tester, session);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Manage Your Money'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('welcome screen navigates to login', (WidgetTester tester) async {
    final session = testSession();
    await pumpApp(tester, session);

    await tester.tap(find.text('Login'));
    await settleRoute(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('welcome screen navigates to register', (WidgetTester tester) async {
    final session = testSession();
    await pumpApp(tester, session);

    await tester.tap(find.text('Get Started'));
    await settleRoute(tester);

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Register'), findsWidgets);
  });
}