/// The fixed set of profile avatars a player can pick from — no photo
/// upload, just a small curated set (like Joker's default profile
/// pictures) rendered as an emoji inside a themed circle. Keeping the
/// set closed (rather than free-form upload) means every seat can
/// render every other seat's avatar with nothing more than the id the
/// server already broadcasts as part of the roster.
class AvatarOption {
  final String id;
  final String emoji;
  const AvatarOption(this.id, this.emoji);
}

const AvatarOption kDefaultAvatar = AvatarOption('lion', '🦁');

const List<AvatarOption> kAvatarOptions = [
  kDefaultAvatar,
  AvatarOption('eagle', '🦅'),
  AvatarOption('fox', '🦊'),
  AvatarOption('wolf', '🐺'),
  AvatarOption('bear', '🐻'),
];

AvatarOption avatarById(String? id) =>
    kAvatarOptions.firstWhere((a) => a.id == id, orElse: () => kDefaultAvatar);
