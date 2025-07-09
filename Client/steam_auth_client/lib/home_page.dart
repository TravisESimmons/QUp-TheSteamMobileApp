import 'package:flutter/material.dart';
import 'quick_match_page.dart';
import 'custom_match_page.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final String? username;
  final String? avatarUrl;
  final String steamId;

  const HomePage({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.steamId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1b2838),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatarUrl != null && avatarUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(avatarUrl!),
                )
              else
                const Icon(Icons.account_circle,
                    size: 80, color: Colors.white30),
              const SizedBox(height: 12),
              Text(
                "Welcome back, ${username ?? 'Player'}!",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: const Text("Quick Match"),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => QuickMatchPage(steamId: steamId),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66c0f4),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text("Custom Match"),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomMatchPage(steamId: steamId),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5c7e10),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Settings"),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsPage(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333F4F),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
