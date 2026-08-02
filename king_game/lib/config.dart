/// PLACEHOLDER — no server is deployed anywhere yet. Point this at the
/// real king_game_server URL once it's hosted.
///
/// MUST be 'wss://' (not 'ws://') for any real deployment: iOS blocks
/// plaintext connections by default (App Transport Security), and
/// Android 9+ does the same (cleartext traffic disabled by default) —
/// neither exception is enabled in this app, on purpose, since a real
/// server should be behind TLS anyway. A real deployment target (Cloud
/// Run, Fly.io, etc.) gives you 'wss://' for free.
///
/// A plain 'ws://LAN-IP:8080/ws' only works for local development on
/// Android, and only from an emulator or a device with cleartext
/// explicitly allowed for that host — not out of the box.
const String defaultServerUrl = 'wss://your-deployed-server.example.com/ws';
