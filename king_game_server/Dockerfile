# Builds a small, self-contained native binary for the King game server,
# plus (see the flutter-build stage) a compiled copy of the Flutter app
# for the web — served alongside the WebSocket endpoint purely so a
# desktop browser can join as a 3rd/4th test player without installing
# anything. Works on any container host (Cloud Run, Fly.io, a plain
# VPS, ...).
#
# king_game_server depends on the sibling king_game_engine package via a
# relative path, so this must be built with the REPO ROOT as context
# (not king_game_server/), run from the repository root:
#
#   docker build -f king_game_server/Dockerfile -t king-game-server .
#   docker run -p 8080:8080 -v king_game_data:/data \
#     -e ACCOUNTS_FILE=/data/accounts.json king-game-server
#
# The volume mount matters: without it, the ban list lives only inside
# the container's writable layer and is lost whenever the container is
# recreated (redeploys, host restarts, autoscaling to a new instance).
FROM dart:stable AS build

WORKDIR /app/king_game_engine
COPY king_game_engine/pubspec.yaml ./
COPY king_game_engine/lib ./lib
RUN dart pub get

WORKDIR /app/king_game_server
COPY king_game_server/pubspec.yaml ./
COPY king_game_server/lib ./lib
COPY king_game_server/bin ./bin
RUN dart pub get
RUN dart compile exe bin/server.dart -o /app/king_game_server_bin

# Test-only web build of the Flutter app itself, so a laptop can open a
# browser tab as an extra seat instead of needing a spare phone. Not a
# real production web target (see BannerAdWidget/AdService's kIsWeb
# guards — ads simply don't run there).
FROM debian:stable-slim AS flutter-build
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter precache --web

WORKDIR /app/king_game_engine
COPY king_game_engine/pubspec.yaml ./
COPY king_game_engine/lib ./lib

WORKDIR /app/king_game
COPY king_game/pubspec.yaml king_game/pubspec.lock ./
RUN flutter pub get
COPY king_game/lib ./lib
COPY king_game/web ./web
COPY king_game/assets ./assets
RUN flutter build web --release

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/king_game_server_bin /app/king_game_server_bin
COPY --from=flutter-build /app/king_game/build/web /app/web_client

ENV PORT=8080
ENV ACCOUNTS_FILE=/data/accounts.json
ENV WEB_CLIENT_DIR=/app/web_client
EXPOSE 8080
VOLUME ["/data"]

ENTRYPOINT ["/app/king_game_server_bin"]
