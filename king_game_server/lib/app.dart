import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'matchmaking.dart';
import 'user_registry.dart';

/// Starts the King game server on [port] (0 lets the OS pick a free
/// port — used by tests). Returns the bound [HttpServer] and the
/// [MatchmakingQueue]/[UserRegistry] it's wired to, so tests can inspect
/// server-side state (e.g. whether a username actually got banned)
/// alongside driving real WebSocket clients against it.
class RunningServer {
  final HttpServer httpServer;
  final MatchmakingQueue queue;
  final UserRegistry registry;

  RunningServer(this.httpServer, this.queue, this.registry);

  int get port => httpServer.port;

  Future<void> close() => httpServer.close(force: true);
}

Future<RunningServer> startServer({
  int port = 0,
  // Loopback-only by default (what every test wants — connections come
  // from the same machine). A real deployment (see bin/server.dart) must
  // pass InternetAddress.anyIPv4 instead: behind Fly.io's proxy (or any
  // reverse proxy/load balancer), the process's own loopback address
  // isn't reachable from outside the machine at all.
  InternetAddress? bindAddress,
  Duration disconnectGrace = const Duration(seconds: 30),
  Duration trickCompleteDelay = const Duration(seconds: 2),
  Duration turnTimeLimit = const Duration(seconds: 20),
  Duration timeBankTotal = const Duration(seconds: 90),
  File? accountsStorageFile,
}) async {
  final registry = UserRegistry(storageFile: accountsStorageFile);
  final queue = MatchmakingQueue(
    registry,
    disconnectGrace: disconnectGrace,
    trickCompleteDelay: trickCompleteDelay,
    turnTimeLimit: turnTimeLimit,
    timeBankTotal: timeBankTotal,
  );

  Handler handler = (Request request) {
    if (request.url.path != 'ws') {
      return Response.notFound('not found');
    }
    final username = request.url.queryParameters['username'];
    if (username == null || username.trim().isEmpty) {
      return Response.badRequest(body: 'username query parameter is required');
    }
    final tableCode = request.url.queryParameters['tableCode'];
    final avatarId = request.url.queryParameters['avatarId'];
    final perConnection = webSocketHandler((WebSocketChannel channel, String? protocol) {
      queue.join(username, channel, avatarId: avatarId, tableCode: tableCode);
    });
    return perConnection(request);
  };

  final httpServer =
      await shelf_io.serve(handler, bindAddress ?? InternetAddress.loopbackIPv4, port);
  // Connections here are long-lived WebSockets, not the short polling
  // HTTP requests idleTimeout's housekeeping timer is meant for; leaving
  // it on just means one more periodic timer to manage for no benefit
  // (and it trips "leaked timer" checks in tests that start/stop a
  // server per test case).
  httpServer.idleTimeout = null;
  return RunningServer(httpServer, queue, registry);
}
