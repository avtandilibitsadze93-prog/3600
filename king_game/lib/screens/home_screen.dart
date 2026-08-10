import 'package:flutter/material.dart';

import '../config.dart';
import '../services/profile_service.dart';
import '../theme/king_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/banner_ad_widget.dart';
import 'online_connect_screen.dart';
import 'players_setup_screen.dart';
import 'private_table_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String avatarId;

  const HomeScreen({super.key, required this.username, required this.avatarId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();
  late String _avatarId = widget.avatarId;

  Future<void> _changeAvatar() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) {
        var selected = _avatarId;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Choose an avatar'),
            content: AvatarPicker(
              selectedId: selected,
              onSelected: (id) => setDialogState(() => selected = id),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected),
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen == _avatarId) return;
    await _profileService.saveAvatarId(chosen);
    if (!mounted) return;
    setState(() => _avatarId = chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('KING', style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('A Georgian trick-taking card game', style: TextStyle(color: KingColors.onFeltSoft)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _changeAvatar,
                        child: Column(
                          children: [
                            AvatarCircle(avatarId: _avatarId, radius: 32),
                            const SizedBox(height: 4),
                            const Text('Change avatar', style: TextStyle(fontSize: 11, color: KingColors.onFeltFaint)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Welcome, ${widget.username}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 40),
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnlineConnectScreen(
                              username: widget.username,
                              avatarId: _avatarId,
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
                            builder: (_) => PrivateTableScreen(username: widget.username, avatarId: _avatarId),
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
