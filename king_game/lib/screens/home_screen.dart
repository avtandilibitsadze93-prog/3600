import 'package:flutter/material.dart';

import '../config.dart';
import '../widgets/banner_ad_widget.dart';
import 'online_connect_screen.dart';
import 'players_setup_screen.dart';

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
                    const Text('კინგი', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('კინგი (კინგი) — ქართული სავაჭრო თამაში', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    Text('მოგესალმებით, $username', style: const TextStyle(fontSize: 16)),
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
                        child: Text('ონლაინ თამაში', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PlayersSetupScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        child: Text('ერთი ტელეფონით (ლოკალურად)', style: TextStyle(fontSize: 16)),
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
