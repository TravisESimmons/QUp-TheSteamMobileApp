import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _didFirstBuildAnim = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndFriends();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _didFirstBuildAnim = true);
    });
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

    // Load all friends
    final batchIds = ids.join(',');

    try {
      final response = await api.getPlayerSummaries(batchIds);
      final List<dynamic> players = response?['players'] ?? [];

      final profiles = players
          .where((player) =>
              player['steamid'] != null &&
              player['personaname'] != null &&
              player['avatarfull'] != null)
          .map<Map<String, dynamic>>((player) {
        return {
          'steamId': player['steamid'] as String,
          'name': player['personaname'] as String,
          'avatar': player['avatarfull'] as String,
        };
      }).toList();

      setState(() => friends = profiles);
    } catch (e) {
      debugPrint("⚠️ Failed to load friend profiles: $e");
    }
  }

  Future<void> runQuickMatch() async {
    if (selectedFriendId == null) return;

    HapticFeedback.lightImpact();
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
    const steamDarker = Color(0xFF171a21);
    const steamAccent = Color(0xFF66c0f4);

    return Scaffold(
      backgroundColor: steamDark,
      appBar: AppBar(
        title: const Text('Quick Match'),
        backgroundColor: steamDarker,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (selectedGameHeader != null)
            Positioned.fill(
              child: Image.network(
                selectedGameHeader!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 128),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 77),
                    Colors.black.withValues(alpha: 140),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSlide(
              offset: _didFirstBuildAnim ? Offset.zero : const Offset(0, 0.03),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _didFirstBuildAnim ? 1 : 0,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: ListView(
                  children: [
                    const Text(
                      "Choose a friend to Quick Match with:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      dropdownColor: steamDark,
                      value: selectedFriendId,
                      hint: const Text(
                        "Select a friend",
                        style: TextStyle(color: Colors.white70),
                      ),
                      items: friends.map<DropdownMenuItem<String>>((friend) {
                        return DropdownMenuItem<String>(
                          value: friend['steamId'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                  friend['avatar'] as String,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                friend['name'] as String,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        SystemSound.play(SystemSoundType.click);
                        HapticFeedback.selectionClick();
                        setState(() {
                          selectedFriendId = value;
                          selectedFriendName = friends
                              .firstWhere((f) => f['steamId'] == value)['name'];
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    AnimatedScale(
                      scale: selectedFriendId == null ? 0.995 : 1,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Run Quick Match"),
                        onPressed:
                            selectedFriendId != null ? runQuickMatch : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: steamAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.985, end: 1).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: isLoading
                          ? const Padding(
                              key: ValueKey('loading'),
                              padding: EdgeInsets.only(top: 8),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: steamAccent,
                                ),
                              ),
                            )
                          : (selectedGameName != null &&
                                  selectedGameHeader != null)
                              ? Container(
                                  key: const ValueKey('result'),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 140),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: steamAccent.withValues(alpha: 56),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "You should play",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          selectedGameHeader!,
                                          height: 160,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        selectedGameName!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: steamAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "with $selectedFriendName",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('empty'),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

