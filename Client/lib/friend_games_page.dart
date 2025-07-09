import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';

class FriendGamesPage extends StatefulWidget {
  final String steamId;
  final String friendName;

  const FriendGamesPage({
    super.key,
    required this.steamId,
    required this.friendName,
  });

  @override
  State<FriendGamesPage> createState() => _FriendGamesPageState();
}

class _FriendGamesPageState extends State<FriendGamesPage> {
  List<dynamic> allGames = [];
  List<dynamic> filteredGames = [];
  bool loading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadFriendGames();
  }

  Future<void> loadFriendGames() async {
    final api = SteamApiService();
    final fetchedGames = await api.fetchGames(widget.steamId);

    // Sort alphabetically by name
    fetchedGames.sort((a, b) => (a['name'] ?? '')
        .toLowerCase()
        .compareTo((b['name'] ?? '').toLowerCase()));

    setState(() {
      allGames = fetchedGames;
      filteredGames = fetchedGames;
      loading = false;
    });
  }

  void filterGames(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredGames = allGames
          .where((game) => (game['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF1b2838);
    const steamBlue = Color(0xFF2a475e);
    const steamAccent = Color(0xFF66C0F4);

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        backgroundColor: const Color(0xFF171a21),
        title: Text("${widget.friendName}'s Games"),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: steamAccent),
            )
          : Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: TextField(
                    onChanged: filterGames,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search games...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: steamBlue,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredGames.isEmpty
                      ? const Center(
                          child: Text(
                            "No matching games found.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredGames.length,
                          itemBuilder: (context, index) {
                            final game = filteredGames[index];
                            final hours =
                                (game['playtime_forever'] ?? 0) / 60.0;
                            final imageUrl = game['img_icon_url'] != null
                                ? "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/${game['appid']}/${game['img_icon_url']}.jpg"
                                : null;

                            return Card(
                              color: steamBlue,
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              width: 54,
                                              height: 54,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.videogame_asset,
                                                      color: Colors.white),
                                            )
                                          : const Icon(Icons.videogame_asset,
                                              size: 54, color: Colors.white),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            game['name'] ?? 'Unknown Game',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${hours.toStringAsFixed(1)} hrs played",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
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
