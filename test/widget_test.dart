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
    expect(find.text('ยินดีต้อนรับสู่ Finly'), findsOneWidget);
    expect(find.text('ลงทะเบียน'), findsOneWidget);
    expect(find.text('ลงชื่อเข้าใช้งาน'), findsOneWidget);
  });

  testWidgets('welcome screen navigates to login', (WidgetTester tester) async {
    final session = testSession();
    await pumpApp(tester, session);

    await tester.tap(find.text('ลงชื่อเข้าใช้งาน'));
    await settleRoute(tester);

    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsOneWidget);
  });

  testWidgets('welcome screen navigates to register', (WidgetTester tester) async {
    final session = testSession();
    await pumpApp(tester, session);

    await tester.tap(find.text('ลงทะเบียน'));
    await settleRoute(tester);

    expect(find.text('สร้างบัญชีใหม่'), findsOneWidget);
  });
}