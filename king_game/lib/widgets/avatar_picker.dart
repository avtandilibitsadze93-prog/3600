import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../theme/king_theme.dart';

/// A row of the 4-5 preset avatars to choose from, with the selected one
/// picked out by a gold ring — used both during registration and when
/// changing your avatar later from the home screen.
class AvatarPicker extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;

  const AvatarPicker({super.key, required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        for (final option in kAvatarOptions)
          GestureDetector(
            onTap: () => onSelected(option.id),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KingColors.feltLight,
                border: Border.all(
                  color: option.id == selectedId ? KingColors.gold : KingColors.onFeltHairline,
                  width: option.id == selectedId ? 3 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(option.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
      ],
    );
  }
}
