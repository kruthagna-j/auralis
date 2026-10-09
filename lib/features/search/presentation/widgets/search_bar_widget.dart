import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/search_screen_services.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode focusNode;
  final bool isDarkMode;
  final Color accentColor;
  final SearchMode searchMode;
  final ValueChanged<String> onSearchTextChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchPressed;
  final VoidCallback onClearPressed;
  final VoidCallback onVoiceSearchPressed;
  final VoidCallback onModeChangedToYouTubeMusic;
  final VoidCallback onModeChangedToYouTube;

  const SearchBarWidget({
    Key? key,
    required this.searchController,
    required this.focusNode,
    required this.isDarkMode,
    required this.accentColor,
    required this.searchMode,
    required this.onSearchTextChanged,
    required this.onSubmitted,
    required this.onSearchPressed,
    required this.onClearPressed,
    required this.onVoiceSearchPressed,
    required this.onModeChangedToYouTubeMusic,
    required this.onModeChangedToYouTube,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = AppDimens.isMobile(context);
    final isDesktop = AppDimens.isDesktop(context);
    final maxWidth = isDesktop ? AppDimens.maxContentWidth : double.infinity;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppDimens.paddingLg : AppDimens.paddingXxl,
        vertical: AppDimens.paddingLg,
      ),
      decoration: BoxDecoration(
        color: MainScreenColors.getBackgroundColor(isDarkMode),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Row(
                children: [
                  if (isMobile) const SizedBox(width: AppDimens.spacingLg),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      focusNode: focusNode,
                      cursorColor: accentColor,
                      style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                      decoration: InputDecoration(
                        hintText: searchMode == SearchMode.youtube
                            ? 'Search YouTube videos...'
                            : 'search_hint'.tr(),
                        hintStyle: AppTextStyles.caption(isDarkMode: isDarkMode)
                            .copyWith(
                              color: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.5),
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.04),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: accentColor.withValues(alpha: 0.9),
                          ),
                        ),
                        filled: true,
                        fillColor: MainScreenColors.getSurfaceColor(
                          isDarkMode,
                        ).withValues(alpha: 0.95),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingXl,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: searchController,
                          builder: (context, value, child) {
                            return value.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.search,
                                          color: MainScreenColors.getTextColor(
                                            isDarkMode,
                                          ).withValues(alpha: 0.5),
                                        ),
                                        onPressed: onSearchPressed,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: MainScreenColors.getTextColor(
                                            isDarkMode,
                                          ).withValues(alpha: 0.5),
                                        ),
                                        onPressed: onClearPressed,
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color: MainScreenColors.getTextColor(
                                        isDarkMode,
                                      ).withValues(alpha: 0.5),
                                    ),
                                    onPressed: onVoiceSearchPressed,
                                    tooltip: 'Voice search',
                                  );
                          },
                        ),
                      ),
                      onChanged: onSearchTextChanged,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingMd),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeToggleButton(
                    context,
                    'YouTube Music',
                    searchMode == SearchMode.youtubeMusic,
                    onModeChangedToYouTubeMusic,
                  ),
                  const SizedBox(width: AppDimens.spacingLg),
                  _buildModeToggleButton(
                    context,
                    'YouTube',
                    searchMode == SearchMode.youtube,
                    onModeChangedToYouTube,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggleButton(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final bool isMobile = AppDimens.isMobile(context);
    final double horizontalPadding = isMobile
        ? AppDimens.paddingSm
        : AppDimens.paddingMd;
    final double verticalPadding = isMobile
        ? AppDimens.spacingXs
        : AppDimens.spacingSm;

    final TextStyle textStyle = AppTextStyles.caption(isDarkMode: isDarkMode)
        .copyWith(
          fontWeight: isSelected
              ? AppTextStyles.weightSemiBold
              : AppTextStyles.weightMedium,
          fontSize: isMobile ? AppTextStyles.fontSizeCaption * 0.9 : null,
          color: isSelected ? Colors.white.withValues(alpha: 0.95) : null,
        );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? accentColor
            : MainScreenColors.getSurfaceColor(
                isDarkMode,
              ).withValues(alpha: 0.8),
        foregroundColor: isSelected
            ? Colors.white
            : MainScreenColors.getTextColor(isDarkMode),
        elevation: isSelected ? 2 : 0,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isMobile ? AppDimens.radiusSm : AppDimens.radiusMd,
          ),
        ),
      ),
      child: Text(text, style: textStyle),
    );
  }
}
