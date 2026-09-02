import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';
import 'services/ad_service.dart';
import 'services/profile_service.dart';
import 'theme/king_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A real card table is played landscape (see the Joker-style reference
  // screens) — lock orientation before the first frame so nothing ever
  // has to lay itself out for portrait at all.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Full-screen: a real card table doesn't have the phone's clock and
  // battery indicator floating over it. immersiveSticky (vs. plain
  // immersive) re-hides the status/nav bars automatically after a swipe
  // reveals them, instead of leaving them up until the next full
  // SystemChrome call.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const KingGameApp());
}

class KingGameApp extends StatelessWidget {
  const KingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'King',
      theme: buildKingTheme(),
      home: const _AppRoot(),
    );
  }
}

/// Decides, once at launch, whether to show the one-time registration
/// screen or go straight to the home screen for an already-known user.
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final _profileService = ProfileService();
  late final Future<(String?, String)> _profile = _loadProfile();

  Future<(String?, String)> _loadProfile() async {
    final username = await _profileService.loadUsername();
    final avatarId = await _profileService.loadAvatarId();
    return (username, avatarId);
  }

  @override
  void initState() {
    super.initState();
    // Post-frame: the ATT prompt (iOS) only shows once the app is
    // actually visible, not while it's still launching.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // google_mobile_ads has no web implementation — the web build only
      // exists for quick desktop-browser testing, not real ad serving.
      if (!kIsWeb) AdService.instance.requestTrackingThenInitialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String?, String)>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final (username, avatarId) = snapshot.data!;
        if (username == null || username.isEmpty) {
          return const RegistrationScreen();
        }
        return HomeScreen(username: username, avatarId: avatarId);
      },
    );
  }
}
