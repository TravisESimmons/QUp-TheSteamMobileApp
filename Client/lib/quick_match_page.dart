import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/steam_api_service.dart';
import 'services/settings_service.dart';

class QuickMatchPage extends StatefulWidget {
  final String steamId;

  const QuickMatchPage({super.key, required this.steamId});

  @override
  State<QuickMatchPage> createState() => _QuickMatchPageState();
}

class _QuickMatchPageState extends State<QuickMatchPage> {
  List<dynamic> friends = [];
  String? selectedFriendId;
  String? selectedFriendName;
  String? selectedGameName;
  String? selectedGameHeader;
  bool isLoading = false;

  final settings = SettingsService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFriends();
  }

  Future<void> _loadSettingsAndFriends() async {
    await settings.load();
    await loadFriends();

    if (settings.rememberQuickMatchFriend) {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('lastQuickMatchFriendId');
      if (savedId != null && friends.any((f) => f['steamId'] == savedId)) {
        setState(() {
          selectedFriendId = savedId;
          selectedFriendName =
              friends.firstWhere((f) => f['steamId'] == savedId)['name'];
        });
      }
    }
  }

  Future<void> loadFriends() async {
    final api = SteamApiService();
    final userData = await api.fetchUserAndFriends(widget.steamId);
    final ids = List<String>.from(userData?['friendIds'] ?? []);

    if (ids.isEmpty) return;

    // Only take first 20 to avoid huge payloads
    final batchIds = ids.take(20).join(',');

    try {
      final response = await api.getPlayerSummaries(batchIds);
      final List<dynamic> players = response?['players'] ?? [];

      final profiles = players.map<Map<String, dynamic>>((player) {
        return {
          'steamId': player['steamid'],
          'name': player['personaname'],
          'avatar': player['avatarfull'],
        };
      }).toList();

      setState(() => friends = profiles);
    } catch (e) {
      debugPrint("⚠️ Failed to load friend profiles: $e");
    }
  }

  Future<void> runQuickMatch() async {
    if (selectedFriendId == null) return;

    setState(() {
      isLoading = true;
      selectedGameName = null;
    });

    final api = SteamApiService();
    final result = await api.fetchQuickMatch(
      me: widget.steamId,
      friend: selectedFriendId!,
    );

    if (settings.rememberQuickMatchFriend) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('lastQuickMatchFriendId', selectedFriendId!);
    }

    setState(() {
      selectedGameName = result?['name'];
      selectedGameHeader = result?['header'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF1b2838);
    const steamAccent = Color(0xFF66c0f4);

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        title: const Text('Quick Match'),
        backgroundColor: steamDark,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (selectedGameHeader != null)
            Positioned.fill(
              child: Image.network(
                selectedGameHeader!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  "Choose a friend to Quick Match with:",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  dropdownColor: steamDark,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  value: selectedFriendId,
                  hint: const Text("Select a friend",
                      style: TextStyle(color: Colors.white70)),
                  items: friends.map<DropdownMenuItem<String>>((friend) {
                    return DropdownMenuItem<String>(
                      value: friend['steamId'],
                      child: Text(friend['name'],
                          style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFriendId = value;
                      selectedFriendName = friends
                          .firstWhere((f) => f['steamId'] == value)['name'];
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Run Quick Match"),
                  onPressed: selectedFriendId != null ? runQuickMatch : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: steamAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                if (isLoading)
                  const Center(
                      child: CircularProgressIndicator(color: steamAccent))
                else if (selectedGameName != null && selectedGameHeader != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "🎮 You Should Play...",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            selectedGameHeader!,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedGameName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF66c0f4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "with $selectedFriendName",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
