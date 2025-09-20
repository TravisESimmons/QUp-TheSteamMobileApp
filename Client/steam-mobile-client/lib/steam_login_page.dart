import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:html' as html;

class SteamLoginPage extends StatefulWidget {
  const SteamLoginPage({super.key});

  @override
  State<SteamLoginPage> createState() => _SteamLoginPageState();
}

class _SteamLoginPageState extends State<SteamLoginPage> {
  WebViewController? _controller;

  final String steamLoginUrl =
      'https://qup-thesteammobileapp.onrender.com/auth/steam'; // Render deployment URL

  // final String steamLoginUrl = 'http://192.168.1.93:3000/auth/steam'; // ← old IP
  // final String steamLoginUrl = 'http://192.168.149.243:3000/auth/steam';

  @override
  void initState() {
    super.initState();

    // Only initialize WebView on mobile platforms
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;

            // Deep link handler for steamqapp://auth-success?steamid=...
            if (url.startsWith("steamqapp://auth-success")) {
              final uri = Uri.parse(url);
              final steamId = uri.queryParameters['steamid'];

              if (steamId != null) {
                // Navigate to profile screen with the SteamID
                Navigator.of(context).pushReplacementNamed(
                  '/main',
                  arguments: steamId,
                );
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ))
        ..loadRequest(Uri.parse(steamLoginUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Steam Login")),
      body: kIsWeb
          ? _buildWebLogin(context)
          : (_controller != null
              ? WebViewWidget(controller: _controller!)
              : const Center(child: CircularProgressIndicator())),
    );
  }

  Widget _buildWebLogin(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videogame_asset,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Steam Login',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Click below to login with Steam',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Login with Steam'),
            onPressed: () {
              // Add web=true parameter to URL for backend detection
              final webLoginUrl = '$steamLoginUrl?web=true';

              // Listen for postMessage from Steam auth popup
              html.window.addEventListener('message', (event) {
                final messageEvent = event as html.MessageEvent;
                final data = messageEvent.data;

                if (data is Map && data['type'] == 'STEAM_LOGIN_SUCCESS') {
                  final steamId = data['steamId'];
                  print('🎮 Received Steam ID from web login: $steamId');
                  if (steamId != null) {
                    // Navigate to main page with actual Steam ID
                    Navigator.of(context)
                        .pushReplacementNamed('/main', arguments: steamId);
                  }
                }
              });

              // Open Steam login in popup window
              html.window
                  .open(webLoginUrl, 'steam_login', 'width=600,height=700');
            },
          ),
        ],
      ),
    );
  }
}
