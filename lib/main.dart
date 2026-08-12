import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_manager.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final session = SessionManager();
  await session.restore();
  runApp(FinlyApp(session: session));
}

class FinlyApp extends StatelessWidget {
  final SessionManager session;

  const FinlyApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SessionManager>.value(
      value: session,
      child: MaterialApp(
        title: 'Finly',
        debugShowCheckedModeBanner: false,
        theme: _theme(),
        home: const SessionGate(),
        routes: {
          '/welcome': (_) => const WelcomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
        },
      ),
    );
  }

  ThemeData _theme() {
    final base = AppTheme.light;
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(
        base.textTheme,
      ),
    );
  }
}

/// Switches between Welcome (unauthenticated) and Home (authenticated)
/// whenever the [SessionManager] status changes.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionManager>();

    return switch (session.status) {
      SessionStatus.restoring => const Scaffold(body: Center(child: CircularProgressIndicator())),
      SessionStatus.unauthenticated => const WelcomeScreen(),
      SessionStatus.authenticated => const HomeScreen(),
    };
  }
}