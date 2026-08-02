import 'dart:convert';
import 'dart:io';

/// One player's account. Username doubles as the account id for now —
/// there's no password/OAuth yet, just enough identity to enforce the
/// leave-early ban across reconnects and queue attempts.
class UserAccount {
  final String username;
  DateTime? bannedUntil;

  UserAccount(this.username, {this.bannedUntil});

  bool get isBanned =>
      bannedUntil != null && bannedUntil!.isAfter(DateTime.now());
}

/// Account registry — in-memory only unless [storageFile] is given, in
/// which case every change (a new username seen, a ban applied) is
/// flushed to that JSON file immediately, and reloaded on startup. That's
/// enough for what this actually needs to survive a restart (the ban
/// list); it isn't a real database, so swap this out first if accounts
/// ever need more than "username -> banned until when".
class UserRegistry {
  final Map<String, UserAccount> _byUsername = {};
  final File? _storageFile;

  UserRegistry({File? storageFile}) : _storageFile = storageFile {
    _load();
  }

  void _load() {
    final file = _storageFile;
    if (file == null || !file.existsSync()) return;
    final raw = file.readAsStringSync();
    if (raw.trim().isEmpty) return;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    for (final entry in data.entries) {
      final bannedUntilRaw = (entry.value as Map<String, dynamic>)['bannedUntil'] as String?;
      _byUsername[entry.key] = UserAccount(
        entry.key,
        bannedUntil: bannedUntilRaw != null ? DateTime.parse(bannedUntilRaw) : null,
      );
    }
  }

  void _save() {
    final file = _storageFile;
    if (file == null) return;
    final data = {
      for (final e in _byUsername.entries)
        e.key: {'bannedUntil': e.value.bannedUntil?.toIso8601String()},
    };
    file.writeAsStringSync(jsonEncode(data));
  }

  UserAccount register(String username) {
    final existing = _byUsername[username];
    if (existing != null) return existing;
    final account = UserAccount(username);
    _byUsername[username] = account;
    _save();
    return account;
  }

  UserAccount? find(String username) => _byUsername[username];

  /// Applied whenever a player abandons a match in progress — either by
  /// explicitly leaving or by never reconnecting within the disconnect
  /// grace period.
  void banForLeavingEarly(String username,
      {Duration duration = const Duration(hours: 4)}) {
    final account = _byUsername[username];
    if (account == null) return;
    account.bannedUntil = DateTime.now().add(duration);
    _save();
  }
}
