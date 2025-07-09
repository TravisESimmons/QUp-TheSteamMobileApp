import 'package:flutter/material.dart';
import 'services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final settings = SettingsService.instance;

  @override
  Widget build(BuildContext context) {
    const steamDark = Color(0xFF171A21);
    const steamBlue = Color(0xFF1B2838);
    const steamAccent = Color(0xFF66C0F4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: steamBlue,
      ),
      backgroundColor: steamDark,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🕹️ My Games Section
          const Text(
            "🎮 My Games",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Sort by Playtime",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Most-played games will appear first",
                style: TextStyle(color: Colors.white54)),
            value: settings.sortGamesByPlaytime,
            activeColor: steamAccent,
            onChanged: (val) => setState(() {
              settings.sortGamesByPlaytime = val;
              settings.save();
            }),
          ),
          const SizedBox(height: 12),
          const Text("Exclude Games Played Under (Hours):",
              style: TextStyle(color: Colors.white70)),
          Slider(
            value: settings.excludeShortGamesHours.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: "${settings.excludeShortGamesHours} hr",
            activeColor: steamAccent,
            onChanged: (val) => setState(() {
              settings.setExcludeThreshold(val.toInt());
              settings.save();
            }),
          ),

          const Divider(height: 32, color: steamAccent),

          // ⚡ Quick Match Section
          const Text(
            "⚡ Quick Match",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Remember Last Match Friend",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Auto-select your last matched friend",
                style: TextStyle(color: Colors.white54)),
            value: settings.rememberQuickMatchFriend,
            activeColor: steamAccent,
            onChanged: (val) => setState(() {
              settings.rememberQuickMatchFriend = val;
              settings.save();
            }),
          ),

          const Divider(height: 32, color: steamAccent),

          // 🎯 Custom Match Section
          const Text(
            "🎯 Custom Match",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Confirm Before Rerolling",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Prompt before showing a new match",
                style: TextStyle(color: Colors.white54)),
            value: settings.confirmBeforeReroll,
            activeColor: steamAccent,
            onChanged: (val) => setState(() {
              settings.confirmBeforeReroll = val;
              settings.save();
            }),
          ),

          const Divider(height: 32, color: steamAccent),

          // ⚙️ App Preferences Section
          const Text(
            "⚙️ App Preferences",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text("Enable Light Theme",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("Switch to a brighter Steam look",
                style: TextStyle(color: Colors.white54)),
            value: settings.lightMode,
            activeColor: steamAccent,
            onChanged: (val) => setState(() {
              settings.lightMode = val;
              settings.save();
            }),
          ),
        ],
      ),
    );
  }
}
