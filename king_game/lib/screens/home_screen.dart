import 'package:flutter/material.dart';

import '../config.dart';
import '../widgets/banner_ad_widget.dart';
import '../theme/king_theme.dart';
import 'online_connect_screen.dart';
import 'players_setup_screen.dart';
import 'private_table_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('KING', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('A Georgian trick-taking card game', style: TextStyle(color: KingColors.onFeltSoft)),
                    const SizedBox(height: 8),
                    Text('Welcome, $username', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 40),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OnlineConnectScreen(
                            username: username,
                            serverUrl: defaultServerUrl,
                          ),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Text('Ranked', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PrivateTableScreen(username: username),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Text('Play with Friends', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlayersSetupScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Text('Local (pass & play)', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
