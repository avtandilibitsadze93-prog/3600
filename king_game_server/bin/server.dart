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

  final running = await startServer(port: port, accountsStorageFile: accountsFile);
  // ignore: avoid_print
  print('King game server listening on ws://0.0.0.0:${running.port}/ws?username=YOU');
  // ignore: avoid_print
  print('Accounts/ban list persisted at: ${accountsFile.absolute.path}');
}
