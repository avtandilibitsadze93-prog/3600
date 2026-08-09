import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';
import 'services/ad_service.dart';
import 'services/profile_service.dart';
import 'theme/king_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KingGameApp());
}

class KingGameApp extends StatelessWidget {
  const KingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'კინგი',
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
  late final Future<String?> _username = ProfileService().loadUsername();

  @override
  void initState() {
    super.initState();
    // Post-frame: the ATT prompt (iOS) only shows once the app is
    // actually visible, not while it's still launching.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.requestTrackingThenInitialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _username,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final username = snapshot.data;
        if (username == null || username.isEmpty) {
          return const RegistrationScreen();
        }
        return HomeScreen(username: username);
      },
    );
  }
}
