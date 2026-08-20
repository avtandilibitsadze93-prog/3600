/// king_game_server, deployed on Fly.io (Frankfurt) as king-game-3600.
///
/// MUST be 'wss://' (not 'ws://'): iOS blocks plaintext connections by
/// default (App Transport Security), and Android 9+ does the same
/// (cleartext traffic disabled by default) — neither exception is
/// enabled in this app, on purpose, since a real server should be
/// behind TLS anyway. Fly.io gives every app 'wss://' for free.
const String defaultServerUrl = 'wss://king-game-3600.fly.dev/ws';
