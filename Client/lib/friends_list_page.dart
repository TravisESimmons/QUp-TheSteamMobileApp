import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';
import 'friend_games_page.dart';

class FriendsListPage extends StatefulWidget {
  final String steamId;

  const FriendsListPage({super.key, required this.steamId});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  List<dynamic> friends = [];
  List<dynamic> filteredFriends = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {
    final api = SteamApiService();
    final data = await api.fetchUserAndFriends(widget.steamId);
    final ids = List<String>.from(data?['friendIds'] ?? []);

    final List<Map<String, dynamic>> profiles = [];

    // Batch profile fetches to avoid 429s (10 per batch)
    const batchSize = 10;
    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize);

      final results = await Future.wait(
        batch.map((id) async {
          try {
            final profile = await api.fetchFriendProfile(id);
            return {
              'steamId': id,
              'name': profile['name'],
              'avatar': profile['avatar'],
            };
          } catch (_) {
            return null;
          }
        }),
      );

      profiles.addAll(results.whereType<Map<String, dynamic>>());

      await Future.delayed(const Duration(milliseconds: 500)); // gentle pause
    }

    profiles.sort(
      (a, b) => a['name'].toLowerCase().compareTo(b['name'].toLowerCase()),
    );

    setState(() {
      friends = profiles;
      filteredFriends = profiles;
      loading = false;
    });
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredFriends = friends
          .where((friend) => friend['name'].toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF171A21);
    const steamBlue = Color(0xFF1B2838);
    const steamAccent = Color(0xFF66C0F4);

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        title: const Text("Friends List"),
        backgroundColor: steamBlue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: steamAccent))
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    cursorColor: steamAccent,
                    decoration: InputDecoration(
                      hintText: 'Search friends...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: steamAccent),
                      filled: true,
                      fillColor: steamBlue,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: updateSearch,
                  ),
                ),
                Expanded(
                  child: filteredFriends.isEmpty
                      ? const Center(
                          child: Text("No friends found.",
                              style: TextStyle(color: Colors.white70)),
                        )
                      : ListView.builder(
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = filteredFriends[index];
                            return Card(
                              color: steamBlue,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      NetworkImage(friend['avatar']),
                                ),
                                title: Text(friend['name'],
                                    style:
                                        const TextStyle(color: Colors.white)),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    color: steamAccent),
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
