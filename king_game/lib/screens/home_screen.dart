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
    // A single compact lobby screen — logo + avatar in a slim top bar,
    // then the 3 game modes as table cards, all visible together
    // without scrolling (the old layout stacked a big centered avatar,
    // welcome text, and 3 full-width buttons tall enough to need 2
    // screens' worth of scrolling to see it all).
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Text('KING', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _changeAvatar,
                    child: Column(
                      children: [
                        AvatarCircle(avatarId: _avatarId, radius: 18),
                        const SizedBox(height: 2),
                        Text(
                          widget.username,
                          style: const TextStyle(fontSize: 10, color: KingColors.onFeltFaint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _TableCard(
                        title: 'Ranked',
                        showSeats: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnlineConnectScreen(
                              username: widget.username,
                              avatarId: _avatarId,
                              serverUrl: defaultServerUrl,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TableCard(
                        title: 'Play with Friends',
                        showSeats: true,
                        icon: Icons.lock,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PrivateTableScreen(username: widget.username, avatarId: _avatarId),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TableCard(
                        title: 'Local (pass & play)',
                        icon: Icons.smartphone,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlayersSetupScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One game mode, drawn as a small table — a Joker-style lobby card
/// instead of a plain full-width button. [showSeats] draws 3 empty
/// seat dots around the table (this game is always exactly 3 players);
/// modes without a real shared table (pass & play) show a plain icon
/// instead.
class _TableCard extends StatelessWidget {
  final String title;
  final bool showSeats;
  final IconData icon;
  final VoidCallback onTap;

  const _TableCard({
    required this.title,
    required this.onTap,
    this.showSeats = false,
    this.icon = Icons.emoji_events,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KingColors.feltLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSeats) _MiniTable(icon: icon) else Icon(icon, color: KingColors.gold, size: 32),
                const SizedBox(height: 8),
                SizedBox(
                  width: 96,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small drawn table with 3 empty seat markers around it — this app
/// has no lobby-status feed yet (no server is deployed to poll), so the
/// seats are decorative rather than a live count; the shape and icon
/// mark what kind of table it is (open matchmaking vs. password-locked).
class _MiniTable extends StatelessWidget {
  final IconData icon;
  const _MiniTable({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 58,
            height: 34,
            decoration: BoxDecoration(
              color: KingColors.feltDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KingColors.gold, width: 1.2),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: KingColors.gold, size: 16),
          ),
          const Positioned(top: 0, child: _SeatDot()),
          const Positioned(bottom: 2, left: 6, child: _SeatDot()),
          const Positioned(bottom: 2, right: 6, child: _SeatDot()),
        ],
      ),
    );
  }
}

class _SeatDot extends StatelessWidget {
  const _SeatDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KingColors.feltDark,
        border: Border.all(color: KingColors.onFeltHairline, width: 1),
      ),
    );
  }
}
