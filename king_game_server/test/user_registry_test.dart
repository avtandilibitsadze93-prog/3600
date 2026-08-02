import 'dart:io';

import 'package:king_game_server/user_registry.dart';
import 'package:test/test.dart';

void main() {
  group('UserRegistry persistence', () {
    late Directory tempDir;
    late File storageFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('king_game_registry_test');
      storageFile = File('${tempDir.path}/accounts.json');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('a ban survives reloading the registry from the same file', () {
      final first = UserRegistry(storageFile: storageFile);
      first.register('ავთო');
      first.banForLeavingEarly('ავთო');
      expect(first.find('ავთო')!.isBanned, isTrue);

      // Simulates a server restart: fresh registry, same backing file.
      final reloaded = UserRegistry(storageFile: storageFile);
      expect(reloaded.find('ავთო'), isNotNull);
      expect(reloaded.find('ავთო')!.isBanned, isTrue);
    });

    test('a never-banned username reloads as not banned', () {
      final first = UserRegistry(storageFile: storageFile);
      first.register('ვასო');

      final reloaded = UserRegistry(storageFile: storageFile);
      expect(reloaded.find('ვასო')!.isBanned, isFalse);
    });

    test('without a storage file, nothing persists across instances', () {
      final first = UserRegistry();
      first.register('გიორგი');
      first.banForLeavingEarly('გიორგი');

      final second = UserRegistry();
      expect(second.find('გიორგი'), isNull);
    });

    test('an expired ban (in the past) reloads as not banned', () {
      final first = UserRegistry(storageFile: storageFile);
      first.register('ძველი');
      // A negative duration lands bannedUntil in the past — same shape a
      // real ban has once its 4 hours have elapsed.
      first.banForLeavingEarly('ძველი', duration: const Duration(hours: -1));

      final reloaded = UserRegistry(storageFile: storageFile);
      expect(reloaded.find('ძველი')!.isBanned, isFalse);
    });
  });
}
