import 'package:flutter/material.dart';
import 'main_navigation_page.dart';
import 'steam_login_page.dart';
import 'login_landing_page.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  runApp(const SteamAuthApp());
}

const _steamDark = Color(0xFF1b2838);
const _steamDarker = Color(0xFF171a21);
const _steamAccent = Color(0xFF66c0f4);
const _steamGreen = Color(0xFF89C623);

final ThemeData darkSteamTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: _steamDark,
  appBarTheme: const AppBarTheme(
    backgroundColor: _steamDarker,
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _steamDarker,
    selectedItemColor: _steamAccent,
    unselectedItemColor: Colors.white70,
  ),
  colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: _steamAccent,
        secondary: _steamGreen,
        surface: const Color(0xFF0f1720),
      ),
  cardTheme: CardThemeData(
    color: const Color(0xFF1f2c3a),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: Color(0xFF0f1720),
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white12,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _steamAccent, width: 1.4),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _steamAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: _steamAccent,
  ),
);

final ThemeData lightSteamTheme = ThemeData.light().copyWith(
  scaffoldBackgroundColor: const Color(0xFFF2F2F2),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFEAEAEA),
    foregroundColor: Color(0xFF1B2838),
    iconTheme: IconThemeData(color: Color(0xFF1B2838)),
    titleTextStyle: TextStyle(color: Color(0xFF1B2838), fontSize: 20),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFEAEAEA),
    selectedItemColor: Color(0xFF1B2838),
    unselectedItemColor: Colors.black54,
  ),
  colorScheme: ThemeData.light().colorScheme.copyWith(
        primary: _steamAccent,
        secondary: _steamGreen,
      ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.black12,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _steamAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
);

class SteamAuthApp extends StatelessWidget {
  const SteamAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: settings.themeNotifier,
      builder: (context, isLightMode, _) {
        return MaterialApp(
          title: 'QUp!',
          debugShowCheckedModeBanner: false,
          theme: isLightMode ? lightSteamTheme : darkSteamTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginLandingPage(),
            '/login': (context) => const SteamLoginPage(),
            '/main': (context) {
              final steamId =
                  ModalRoute.of(context)!.settings.arguments as String;
              return MainNavigationPage(steamId: steamId);
            },
          },
        );
      },
    );
  }
}
