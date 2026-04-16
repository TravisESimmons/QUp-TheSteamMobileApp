import 'dart:html' as html;

void setupWebLogin(String webLoginUrl, Function(String) onSuccess) {
  // Listen for postMessage from Steam auth popup
  html.window.addEventListener('message', (event) {
    final messageEvent = event as html.MessageEvent;
    final data = messageEvent.data;

    if (data is Map && data['type'] == 'STEAM_LOGIN_SUCCESS') {
      final steamId = data['steamId'];
      print('🎮 Received Steam ID from web login: $steamId');
      if (steamId != null) {
        onSuccess(steamId);
      }
    }
  });

  // Open Steam login in popup window
  html.window.open(webLoginUrl, 'steam_login', 'width=600,height=700');
}
