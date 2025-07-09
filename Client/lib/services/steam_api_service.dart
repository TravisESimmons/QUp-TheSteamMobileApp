import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamApiService {
  static const String baseUrl = 'http://192.168.1.93:3000';
  // static const String baseUrl = "http://192.168.149.243:3000";

  Future<Map<String, dynamic>?> fetchUserAndFriends(String steamId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-info?steamid=$steamId'),
      );

      print("🌐 /user-info Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("❌ fetchUserAndFriends error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchFriendProfile(String steamId) async {
    final uri = Uri.parse('$baseUrl/api/friend-profile?steamid=$steamId');
    final response = await http.get(uri);
    return jsonDecode(response.body);
  }

  Future<List<dynamic>> fetchGames(String steamId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/friend-games?steamid=$steamId'),
      );

      print("🎮 /friend-games Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['games'] ?? [];
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      print("❌ fetchGames error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPlayerSummaries(String steamIds) async {
    // final uri = Uri.parse(
    //     'http://192.168.1.93:3000/api/player-summaries?steamids=$steamIds');
    final uri = Uri.parse('$baseUrl/api/player-summaries?steamids=$steamIds');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }

  /// 🔹 Fetches shared multiplayer-compatible games with optional filters
  Future<List<dynamic>> fetchCustomMatch({
    required List<String> steamIds,
    List<String> genres = const [],
    List<String> tags = const [],
    int? maxPlaytime,
    double? maxSizeGB,
    double? minSizeGB,
    bool coopOnly = false,
    bool versusOnly = false,
    int? minYear,
    int? maxYear,
    bool freeOnly = false,
    bool hiddenGems = false,
  }) async {
    try {
      final queryParams = {
        'steamids': steamIds.join(','),
        if (genres.isNotEmpty) 'genres': genres.join(','),
        if (tags.isNotEmpty) 'tags': tags.join(','),
        if (maxPlaytime != null) 'maxPlay': maxPlaytime.toString(),
        if (maxSizeGB != null) 'maxSize': maxSizeGB.toString(),
        if (minSizeGB != null) 'minSize': minSizeGB.toString(),
        if (coopOnly) 'coop': 'true',
        if (versusOnly) 'versus': 'true',
        if (minYear != null) 'minYear': minYear.toString(),
        if (maxYear != null) 'maxYear': maxYear.toString(),
        if (freeOnly) 'freeOnly': '1',
        if (hiddenGems) 'hiddenGems': '1',
        'limit': '20',
      };

      final uri = Uri.parse('$baseUrl/api/custom-match')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      print("🎯 /custom-match Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        throw Exception('Custom match API failed');
      }
    } catch (e) {
      print("❌ fetchCustomMatch error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchQuickMatch({
    required String me,
    required String friend,
  }) async {
    final url = Uri.parse('$baseUrl/api/quick-match?me=$me&friend=$friend');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['result'];
    } else {
      print("❌ Failed to fetch quick match: ${res.body}");
      return null;
    }
  }

  Future<void> warmLoadAllData(String steamId) async {
    final userInfo = await fetchUserAndFriends(steamId);
    final friendIds = (userInfo?['friends'] as List<dynamic>?)
        ?.map((f) => f['steamId']?.toString())
        .where((id) => id != null)
        .toList();

    if (friendIds == null || friendIds.isEmpty) return;

    print("🔥 Warm loading game data for ${friendIds.length} friends...");
    for (final id in friendIds) {
      await fetchGames(id!);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print("✅ Warm load complete.");
  }
}
