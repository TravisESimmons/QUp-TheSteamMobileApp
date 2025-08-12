import 'package:flutter/material.dart';
import 'services/steam_api_service.dart';
import 'match_result_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomMatchPage extends StatefulWidget {
  final String steamId;

  const CustomMatchPage({super.key, required this.steamId});

  @override
  State<CustomMatchPage> createState() => _CustomMatchPageState();
}

class _CustomMatchPageState extends State<CustomMatchPage> {
  final List<String> allGenres = ['Action', 'RPG', 'Strategy', 'Simulation'];

  List<dynamic> friends = [];
  List<String> selectedFriendIds = [];
  List<String> selectedGenres = [];

  bool coopOnly = false;
  bool versusOnly = false;
  int minYear = 2000;
  int maxYear = DateTime.now().year;
  double minSize = 0;
  double maxSize = 200;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultsAndFriends();
  }

  Future<void> _loadDefaultsAndFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final storedGenres = prefs.getStringList('defaultGenres') ?? [];

    setState(() {
      selectedGenres = storedGenres;
    });

    await loadFriends();
  }

  Future<void> loadFriends() async {
    final api = SteamApiService();
    final data = await api.fetchUserAndFriends(widget.steamId);
    final ids = List<String>.from(data?['friendIds'] ?? []);

    final List<Map<String, dynamic>> friendProfiles = [];

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

      friendProfiles.addAll(results.whereType<Map<String, dynamic>>());

      await Future.delayed(const Duration(milliseconds: 500)); // prevent 429s
    }

    setState(() {
      friends = friendProfiles;
      loading = false;
    });
  }

  void toggleFriend(String id) {
    setState(() {
      if (selectedFriendIds.contains(id)) {
        selectedFriendIds.remove(id);
      } else if (selectedFriendIds.length < 3) {
        selectedFriendIds.add(id);
      }
    });
  }

  void toggleGenre(String genre) {
    setState(() {
      selectedGenres.contains(genre)
          ? selectedGenres.remove(genre)
          : selectedGenres.add(genre);
    });
  }

  void findMatch() async {
    final allSteamIds = [widget.steamId, ...selectedFriendIds];
    if (selectedFriendIds.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF66C0F4)),
      ),
    );

    final api = SteamApiService();
    final results = await api.fetchCustomMatch(
      steamIds: allSteamIds,
      genres: selectedGenres,
      coopOnly: coopOnly,
      versusOnly: versusOnly,
      minYear: minYear,
      maxYear: maxYear,
      minSizeGB: minSize,
      maxSizeGB: maxSize,
    );

    Navigator.pop(context);

    if (results.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchResultPage(
            results: results,
            initialIndex: 0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No matches found.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF171A21);
    const steamBlue = Color(0xFF1B2838);
    const steamGreen = Color(0xFF89C623);

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        backgroundColor: steamBlue,
        title: const Text('Custom Match'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: steamGreen))
          : Column(
              children: [
                _buildFilterTile(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select up to 3 friends:",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        ...friends.map((f) {
                          final selected =
                              selectedFriendIds.contains(f['steamId']);
                          return Card(
                            color: steamBlue,
                            child: CheckboxListTile(
                              value: selected,
                              onChanged: (_) => toggleFriend(f['steamId']),
                              title: Text(f['name'],
                                  style: const TextStyle(color: Colors.white)),
                              secondary: CircleAvatar(
                                backgroundImage: NetworkImage(f['avatar']),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.lightBlueAccent,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text("Find a Match"),
          onPressed: selectedFriendIds.isNotEmpty ? findMatch : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: steamGreen,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTile() {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text("Filters",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      collapsedBackgroundColor: Colors.grey[850],
      backgroundColor: Colors.grey[900],
      iconColor: Colors.lightBlueAccent,
      collapsedIconColor: Colors.lightBlueAccent,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Wrap(
                spacing: 6,
                children: allGenres
                    .map((g) => FilterChip(
                          label: Text(g),
                          labelStyle: const TextStyle(color: Colors.white),
                          selected: selectedGenres.contains(g),
                          onSelected: (_) => toggleGenre(g),
                          selectedColor: Colors.blueAccent,
                          backgroundColor: Colors.grey[800],
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: coopOnly,
                    onChanged: (val) => setState(() => coopOnly = val ?? false),
                    activeColor: Colors.lightBlueAccent,
                  ),
                  const Text("Co-op only",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: versusOnly,
                    onChanged: (val) =>
                        setState(() => versusOnly = val ?? false),
                    activeColor: Colors.lightBlueAccent,
                  ),
                  const Text("Versus only",
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Min Year:",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: minYear,
                    dropdownColor: Colors.grey[850],
                    items: [
                      for (var y = 2000; y <= DateTime.now().year; y++)
                        DropdownMenuItem(
                            value: y,
                            child: Text("$y",
                                style: const TextStyle(color: Colors.white)))
                    ],
                    onChanged: (val) => setState(() => minYear = val ?? 2000),
                  ),
                  const SizedBox(width: 24),
                  const Text("Max Year:",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: maxYear,
                    dropdownColor: Colors.grey[850],
                    items: [
                      for (var y = 2000; y <= DateTime.now().year; y++)
                        DropdownMenuItem(
                            value: y,
                            child: Text("$y",
                                style: const TextStyle(color: Colors.white)))
                    ],
                    onChanged: (val) =>
                        setState(() => maxYear = val ?? DateTime.now().year),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Min Size (GB):",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: minSize,
                      min: 0,
                      max: 200,
                      divisions: 40,
                      label: "${minSize.toStringAsFixed(0)} GB",
                      onChanged: (val) => setState(() => minSize = val),
                      activeColor: Colors.lightBlueAccent,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Max Size (GB):",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: maxSize,
                      min: 0,
                      max: 200,
                      divisions: 40,
                      label: "${maxSize.toStringAsFixed(0)} GB",
                      onChanged: (val) => setState(() => maxSize = val),
                      activeColor: Colors.lightBlueAccent,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
