import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';
import 'services/settings_service.dart';

class MyGamesPage extends StatefulWidget {
  final String steamId;

  const MyGamesPage({super.key, required this.steamId});

  @override
  State<MyGamesPage> createState() => _MyGamesPageState();
}

class _MyGamesPageState extends State<MyGamesPage> {
  List<dynamic> games = [];
  List<dynamic> filteredGames = [];
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadSettingsThenGames();
  }

  Future<void> _loadSettingsThenGames() async {
    await SettingsService.instance.load();
    await loadMyGames();
  }

  Future<void> loadMyGames() async {
    final api = SteamApiService();
    final settings = SettingsService.instance;

    final fetchedGames = await api.fetchGames(widget.steamId);
    final minMinutes = settings.excludeShortGamesHours * 60;

    final filtered = fetchedGames.where((game) {
      final playtime = game['playtime_forever'] ?? 0;
      return playtime >= minMinutes;
    }).toList();

    // ✅ Sort by playtime OR alphabetically
    if (settings.sortGamesByPlaytime) {
      filtered.sort((a, b) =>
          (b['playtime_forever'] ?? 0).compareTo(a['playtime_forever'] ?? 0));
    } else {
      filtered.sort((a, b) => (a['name'] ?? '')
          .toLowerCase()
          .compareTo((b['name'] ?? '').toLowerCase()));
    }

    setState(() {
      games = filtered;
      filteredGames = filtered;
      loading = false;
    });
  }

  void filterGames(String query) {
    final settings = SettingsService.instance;
    final minMinutes = settings.excludeShortGamesHours * 60;

    final filtered = games.where((game) {
      final name = (game['name'] ?? '').toLowerCase();
      final playtime = game['playtime_forever'] ?? 0;
      return name.contains(query.toLowerCase()) && playtime >= minMinutes;
    }).toList();

    // ✅ Keep sorting consistent
    if (settings.sortGamesByPlaytime) {
      filtered.sort((a, b) =>
          (b['playtime_forever'] ?? 0).compareTo(a['playtime_forever'] ?? 0));
    } else {
      filtered.sort((a, b) => (a['name'] ?? '')
          .toLowerCase()
          .compareTo((b['name'] ?? '').toLowerCase()));
    }

    setState(() {
      searchQuery = query;
      filteredGames = filtered;
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
        title: const Text("My Games"),
        backgroundColor: steamBlue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: steamAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    onChanged: filterGames,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search games...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: steamBlue,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (filteredGames.isEmpty)
                  const Center(
                    child: Text("No games found.",
                        style: TextStyle(color: Colors.white70)),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredGames.length,
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        return Card(
                          color: steamBlue,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: game['img_icon_url'] != null
                                ? Image.network(
                                    "https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/apps/${game['appid']}/${game['img_icon_url']}.jpg",
                                    width: 40,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.videogame_asset,
                                        color: Colors.white70),
                                  )
                                : const Icon(Icons.videogame_asset,
                                    color: Colors.white70),
                            title: Text(
                              game['name'] ?? "Unknown Game",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${(game['playtime_forever'] / 60).toStringAsFixed(1)} hrs",
                              style: const TextStyle(color: Colors.white70),
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
