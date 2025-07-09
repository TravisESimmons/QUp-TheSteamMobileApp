// models/steam_user.dart
class SteamUser {
  final String steamId;
  final String name;
  final String avatar;

  SteamUser({required this.steamId, required this.name, required this.avatar});

  factory SteamUser.fromJson(Map<String, dynamic> json) {
    return SteamUser(
      steamId: json['steamId'],
      name: json['name'],
      avatar: json['avatar'],
    );
  }
}
