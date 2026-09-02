import 'dart:io';

import 'package:king_game_server/app.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  // Where the ban list survives a restart. NOTE: on a platform with an
  // ephemeral/non-persistent filesystem (e.g. Cloud Run without a
  // mounted volume), this file — and every ban in it — disappears on
  // redeploy or when the instance is recycled. Fine for a single
  // long-running VM/container with a real disk; mount a volume at this
  // path (or point ACCOUNTS_FILE at one) for anything else.
  final accountsPath = Platform.environment['ACCOUNTS_FILE'] ?? 'data/accounts.json';
  final accountsFile = File(accountsPath);
  await accountsFile.parent.create(recursive: true);

  // Test-only browser client — see startServer's webClientDir doc. Only
  // wired up if the directory actually exists (the Dockerfile's
  // flutter-build stage puts one at WEB_CLIENT_DIR; a bare `dart run`
  // during local development has no such thing, and that's fine).
  final webClientPath = Platform.environment['WEB_CLIENT_DIR'];
  final webClientDir = webClientPath != null && await Directory(webClientPath).exists()
      ? Directory(webClientPath)
      : null;

  final running = await startServer(
    port: port,
    bindAddress: InternetAddress.anyIPv4,
    accountsStorageFile: accountsFile,
    webClientDir: webClientDir,
  );
  // ignore: avoid_print
  print('King game server listening on ws://0.0.0.0:${running.port}/ws?username=YOU');
  // ignore: avoid_print
  print('Accounts/ban list persisted at: ${accountsFile.absolute.path}');
}
