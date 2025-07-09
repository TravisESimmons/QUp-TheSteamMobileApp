import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SteamLoginPage extends StatefulWidget {
  const SteamLoginPage({super.key});

  @override
  State<SteamLoginPage> createState() => _SteamLoginPageState();
}

class _SteamLoginPageState extends State<SteamLoginPage> {
  late final WebViewController _controller;

  final String steamLoginUrl =
      'http://192.168.1.93:3000/auth/steam'; // ← for real phone

  // final String steamLoginUrl = 'http://192.168.149.243:3000/auth/steam';

  @override
  void initState() {
    super.initState();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Steam Login")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
