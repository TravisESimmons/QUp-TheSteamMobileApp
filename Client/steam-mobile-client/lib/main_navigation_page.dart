import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';
import 'home_page.dart';
import 'my_games_page.dart';
import 'friends_list_page.dart';

import 'settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  final String steamId;

  const MainNavigationPage({super.key, required this.steamId});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  String? steamUsername;
  String? steamAvatarUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSteamProfile();
  }

  Future<void> loadSteamProfile() async {
    final api = SteamApiService();
    print('🔍 Loading profile for Steam ID: ${widget.steamId}');
    final data = await api.fetchUserAndFriends(widget.steamId);

    print('📡 API Response: $data');

    if (data != null && data['profile'] != null) {
      setState(() {
        steamUsername = data['profile']['name'] ?? 'Player';
        steamAvatarUrl = data['profile']['avatar'] ?? '';
        isLoading = false;
      });
      print('✅ Profile loaded: $steamUsername');
    } else {
      // Handle error or fallback here
      setState(() {
        steamUsername = 'Player';
        steamAvatarUrl = '';
        isLoading = false;
      });
      print('❌ Profile load failed - using fallback');
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1b2838),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF66c0f4))),
      );
    }

    final List<Widget> _pages = [
      HomePage(
        username: steamUsername,
        avatarUrl: steamAvatarUrl,
        steamId: widget.steamId, // ✅ add this
      ),
      MyGamesPage(steamId: widget.steamId),
      FriendsListPage(steamId: widget.steamId), // 👈 New tab
      SettingsPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.videogame_asset), label: 'My Games'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Friends'), // 👈 New tab
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
