import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'room.dart';
import 'user_registry.dart';

/// Matches the Flutter app's kDefaultAvatar.id — used when a client
/// connects without an avatarId (older client, or a query param that
/// somehow came through empty).
const _defaultAvatarId = 'lion';

class _Waiting {
  final String username;
  final String avatarId;
  final WebSocketChannel channel;
  _Waiting(this.username, this.avatarId, this.channel);
}

/// FIFO queue of players waiting for a match. As soon as 3 are queued,
/// they're pulled off and formed into a [Room]. Rejects (with a clear
/// message, then closes the socket) anyone currently serving the
/// leave-early ban.
class MatchmakingQueue {
  final UserRegistry registry;
  final Duration disconnectGrace;
  final Duration trickCompleteDelay;
  final Map<String, Room> activeRooms = {};
  final List<_Waiting> _waiting = [];

  /// Private tables: players who supply the same [tableCode] (a password
  /// they've agreed on with friends, e.g. over messenger) wait together
  /// here instead of the public FIFO queue, and only form a room once
  /// exactly 3 people have shown up with that same code.
  final Map<String, List<_Waiting>> _privateWaiting = {};
  int _nextRoomId = 1;

  MatchmakingQueue(
    this.registry, {
    this.disconnectGrace = const Duration(seconds: 30),
    this.trickCompleteDelay = const Duration(seconds: 2),
  });

  int get waitingCount => _waiting.length;

  void join(String username, WebSocketChannel channel, {String? avatarId, String? tableCode}) {
    final account = registry.register(username);
    if (account.isBanned) {
      channel.sink.add(jsonEncode({
        'type': 'error',
        'message':
            "You're temporarily blocked for leaving a previous game early. Please try again later.",
      }));
      channel.sink.close();
      return;
    }

    // A mobile connection can drop for reasons that have nothing to do
    // with leaving the game (wifi/cellular handoff, a moment out of
    // signal). If this username already has a seat waiting out its
    // disconnect grace period, route them back into it instead of
    // queuing them into a brand new match.
    for (final room in activeRooms.values) {
      final seat = room.seatForUsername(username);
      if (seat == null) continue;
      if (room.canReconnect(seat)) {
        room.reconnect(seat, channel);
      } else {
        channel.sink.add(jsonEncode({
          'type': 'error',
          'message': 'This user is already in this game or has already been replaced by a bot.',
        }));
        channel.sink.close();
      }
      return;
    }

    final resolvedAvatarId = avatarId != null && avatarId.isNotEmpty ? avatarId : _defaultAvatarId;

    final code = tableCode?.trim();
    if (code != null && code.isNotEmpty) {
      final group = _privateWaiting.putIfAbsent(code, () => []);
      group.add(_Waiting(username, resolvedAvatarId, channel));
      channel.sink.add(jsonEncode({'type': 'queued', 'waitingCount': group.length}));
      _tryFormPrivateRoom(code);
      return;
    }

    _waiting.add(_Waiting(username, resolvedAvatarId, channel));
    channel.sink.add(jsonEncode({'type': 'queued', 'waitingCount': _waiting.length}));
    _tryFormRoom();
  }

  void _tryFormRoom() {
    while (_waiting.length >= 3) {
      final trio = _waiting.sublist(0, 3);
      _waiting.removeRange(0, 3);
      _formRoom(trio);
    }
  }

  void _tryFormPrivateRoom(String code) {
    final group = _privateWaiting[code];
    if (group == null) return;
    while (group.length >= 3) {
      final trio = group.sublist(0, 3);
      group.removeRange(0, 3);
      _formRoom(trio);
    }
    if (group.isEmpty) _privateWaiting.remove(code);
  }

  void _formRoom(List<_Waiting> trio) {
    final roomId = 'room-${_nextRoomId++}';
    activeRooms[roomId] = Room(
      id: roomId,
      usernames: [for (final w in trio) w.username],
      avatarIds: [for (final w in trio) w.avatarId],
      channels: [for (final w in trio) w.channel],
      registry: registry,
      disconnectGrace: disconnectGrace,
      trickCompleteDelay: trickCompleteDelay,
      onFinished: activeRooms.remove,
    );
  }
}
