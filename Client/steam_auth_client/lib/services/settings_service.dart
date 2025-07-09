import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();

  // 🆕 ValueNotifier to track theme changes
  final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

  // Existing settings
  bool debugMode = false;
  bool privacyMode = false;
  bool sortGamesByPlaytime = true;
  int excludeShortGamesHours = 1;
  bool confirmBeforeReroll = false;

  // ✅ New settings
  bool lightMode = false;
  bool autoFocusSearch = false;
  bool confirmReroll = false;
  bool rememberQuickMatchFriend = false;
  int startupPage = 0;

  SettingsService._internal();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    debugMode = prefs.getBool('debugMode') ?? false;
    privacyMode = prefs.getBool('privacyMode') ?? false;
    sortGamesByPlaytime = prefs.getBool('sortGamesByPlaytime') ?? true;
    excludeShortGamesHours = prefs.getInt('excludeShortGamesHours') ?? 1;
    confirmBeforeReroll = prefs.getBool('confirmBeforeReroll') ?? false;

    lightMode = prefs.getBool('lightMode') ?? false;
    autoFocusSearch = prefs.getBool('autoFocusSearch') ?? false;
    confirmReroll = prefs.getBool('confirmReroll') ?? false;
    rememberQuickMatchFriend =
        prefs.getBool('rememberQuickMatchFriend') ?? false;
    startupPage = prefs.getInt('startupPage') ?? 0;

    themeNotifier.value = lightMode; // 🔄 reflect current theme after load
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('debugMode', debugMode);
    await prefs.setBool('privacyMode', privacyMode);
    await prefs.setBool('sortGamesByPlaytime', sortGamesByPlaytime);
    await prefs.setInt('excludeShortGamesHours', excludeShortGamesHours);
    await prefs.setBool('confirmBeforeReroll', confirmBeforeReroll);

    await prefs.setBool('lightMode', lightMode);
    await prefs.setBool('autoFocusSearch', autoFocusSearch);
    await prefs.setBool('confirmReroll', confirmReroll);
    await prefs.setBool('rememberQuickMatchFriend', rememberQuickMatchFriend);
    await prefs.setInt('startupPage', startupPage);

    themeNotifier.value = lightMode; // 🔄 trigger rebuild on theme change
  }

  void setExcludeThreshold(int hours) => excludeShortGamesHours = hours;
}
