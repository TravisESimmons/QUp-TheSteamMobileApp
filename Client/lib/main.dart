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

final ThemeData darkSteamTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF1b2838),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171a21),
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF171a21),
    selectedItemColor: Color(0xFF66c0f4),
    unselectedItemColor: Colors.white70,
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
        primary: const Color(0xFF66C0F4),
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
          title: 'QueueUp',
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
