import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';
import 'user_registry.dart';

class _Waiting {
  final String username;
  final WebSocketChannel channel;
  _Waiting(this.username, this.channel);
}

/// FIFO queue of players waiting for a match. As soon as 3 are queued,
/// they're pulled off and formed into a [Room]. Rejects (with a clear
/// message, then closes the socket) anyone currently serving the
/// leave-early ban.
class MatchmakingQueue {
  final UserRegistry registry;
  final Duration disconnectGrace;
  final Map<String, Room> activeRooms = {};
  final List<_Waiting> _waiting = [];
  int _nextRoomId = 1;

  MatchmakingQueue(this.registry, {this.disconnectGrace = const Duration(seconds: 30)});

  int get waitingCount => _waiting.length;

  void join(String username, WebSocketChannel channel) {
    final account = registry.register(username);
    if (account.isBanned) {
      channel.sink.add(jsonEncode({
        'type': 'error',
        'message':
            'თქვენ დროებით დაბლოკილი ხართ, რადგან წინა თამაში ვადაზე ადრე დატოვეთ. სცადეთ მოგვიანებით.',
      }));
      channel.sink.close();
      return;
    }
    _waiting.add(_Waiting(username, channel));
    channel.sink.add(jsonEncode({'type': 'queued', 'waitingCount': _waiting.length}));
    _tryFormRoom();
  }

  void _tryFormRoom() {
    while (_waiting.length >= 3) {
      final trio = _waiting.sublist(0, 3);
      _waiting.removeRange(0, 3);
      final roomId = 'room-${_nextRoomId++}';
      activeRooms[roomId] = Room(
        id: roomId,
        usernames: [for (final w in trio) w.username],
        channels: [for (final w in trio) w.channel],
        registry: registry,
        disconnectGrace: disconnectGrace,
        onFinished: activeRooms.remove,
      );
    }
  }
}
