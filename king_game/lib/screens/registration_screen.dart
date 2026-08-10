import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../services/profile_service.dart';
import '../theme/king_theme.dart';
import '../widgets/avatar_picker.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _controller = TextEditingController();
  final _profileService = ProfileService();
  String? _error;
  String _avatarId = kDefaultAvatar.id;

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name');
      return;
    }
    await _profileService.saveUsername(name);
    await _profileService.saveAvatarId(_avatarId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(username: name, avatarId: _avatarId)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('King', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Registration', style: TextStyle(fontSize: 18, color: KingColors.onFeltSoft)),
                  const SizedBox(height: 32),
                  const Text('Choose an avatar', style: TextStyle(color: KingColors.onFeltSoft)),
                  const SizedBox(height: 12),
                  AvatarPicker(
                    selectedId: _avatarId,
                    onSelected: (id) => setState(() => _avatarId = id),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Your name',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
