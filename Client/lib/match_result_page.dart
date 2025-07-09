import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/settings_service.dart';

class MatchResultPage extends StatefulWidget {
  final List<dynamic> results;
  final int initialIndex;

  const MatchResultPage({
    super.key,
    required this.results,
    required this.initialIndex,
  });

  @override
  State<MatchResultPage> createState() => _MatchResultPageState();
}

class _MatchResultPageState extends State<MatchResultPage> {
  late SettingsService settings;
  late int currentIndex;
  bool debugMode = false;
  bool compactImageMode = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    settings = SettingsService.instance; // ✅ this assigns to the `late` field
    await settings.load();
    setState(() {
      debugMode = settings.debugMode;
    });
  }

  Future<void> reroll() async {
    if (settings.confirmBeforeReroll) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Reroll?"),
          content: const Text("Are you sure you want to try another match?"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes")),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      currentIndex = (currentIndex + 1) % widget.results.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.results[currentIndex];
    final gameName = game['name'];
    final bannerUrl = game['banner'];
    final headerUrl = game['header_image'];

    final imageUrl = bannerUrl ?? headerUrl;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔹 Blurred full background (always covers screen)
          Positioned.fill(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.5),
                    colorBlendMode: BlendMode.darken,
                  )
                : const SizedBox(),
          ),

          // 🔹 Foreground splash content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "🎮 You Should Play...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🖼️ Banner/Header image with fixed height
                  if (imageUrl != null)
                    Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 24),
                  Text(
                    gameName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF66c0f4),
                    ),
                  ),

                  if (debugMode) ...[
                    const SizedBox(height: 10),
                    Text(
                      "AppID: ${game['appid']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (game['estimatedSizeGB'] != null)
                      Text(
                        "Size: ${game['estimatedSizeGB']} GB",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if (game['releaseYear'] != null)
                      Text(
                        "Year: ${game['releaseYear']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],

                  const SizedBox(height: 36),
                  Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Go Back"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66c0f4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: reroll,
                        icon: const Icon(Icons.shuffle),
                        label: const Text("Try Another"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF89C623),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
