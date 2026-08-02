# Builds a small, self-contained native binary for the King game server.
# Works on any container host (Cloud Run, Fly.io, a plain VPS, ...).
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

FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /app/king_game_server_bin /app/king_game_server_bin

ENV PORT=8080
ENV ACCOUNTS_FILE=/data/accounts.json
EXPOSE 8080
VOLUME ["/data"]

ENTRYPOINT ["/app/king_game_server_bin"]
