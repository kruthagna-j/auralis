import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../screens/metadata_editor_screen.dart';

class LocalSongOptionsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> song;
  final bool isDarkMode;
  final VoidCallback onPlay;

  const LocalSongOptionsBottomSheet({
    Key? key,
    required this.song,
    required this.isDarkMode,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = MainScreenColors.getTextColor(isDarkMode);
    final backgroundColor = MainScreenColors.getBackgroundColor(isDarkMode);

    return Material(
      color: backgroundColor,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimens.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    song['title'] ?? song['name'] ?? 'Unknown Title',
                    style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.play_arrow, color: textColor),
            title: Text(
              'play'.tr(),
              style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
            ),
            onTap: () {
              Navigator.pop(context);
              onPlay();
            },
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.edit, color: textColor),
            title: Text(
              'edit_metadata'.tr(),
              style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MetadataEditorScreen(song: song),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimens.spacingLg),
        ],
      ),
    );
  }
}
