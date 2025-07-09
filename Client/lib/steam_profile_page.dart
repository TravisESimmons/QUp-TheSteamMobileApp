import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';
import 'friend_games_page.dart';

class SteamProfilePage extends StatefulWidget {
  final String steamId;

  const SteamProfilePage({super.key, required this.steamId});

  @override
  State<SteamProfilePage> createState() => _SteamProfilePageState();
}

class _SteamProfilePageState extends State<SteamProfilePage> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSteamData();
  }

  Future<void> loadSteamData() async {
    final api = SteamApiService();
    final data = await api.fetchUserAndFriends(widget.steamId);
    setState(() {
      userData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF171A21);
    const steamBlue = Color(0xFF1B2838);
    const steamAccent = Color(0xFF66C0F4);

    if (loading) {
      return const Scaffold(
        backgroundColor: steamDark,
        body: Center(child: CircularProgressIndicator(color: steamAccent)),
      );
    }

    if (userData == null) {
      return const Scaffold(
        backgroundColor: steamDark,
        body: Center(
          child: Text('Failed to load data',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final profile = userData!['profile'];
    final friends = userData!['friends'];

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        title: Text("Welcome, ${profile['name']}"),
        backgroundColor: const Color(0xFF1b2838),
        foregroundColor: Colors.white, // ✅ makes title + back arrow white
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(profile['avatar']),
          ),
          const SizedBox(height: 10),
          Text(
            profile['name'],
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(color: steamAccent, thickness: 1.5, height: 40),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Friends",
                style: TextStyle(fontSize: 20, color: steamAccent),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Card(
                  color: steamBlue,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(friend['avatar']),
                    ),
                    title: Text(friend['name'],
                        style: const TextStyle(color: Colors.white)),
                    trailing:
                        const Icon(Icons.arrow_forward_ios, color: steamAccent),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FriendGamesPage(
                            steamId: friend['steamId'],
                            friendName: friend['name'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
