import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/components/content_details_shimmer.dart';

class PlaylistAlbumContentShimmer {
  static const double _desktopBreakpoint = AppDimens.breakpointDesktop;

  static Widget buildShimmer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;
    final isDarkMode =
        Provider.of<SettingsProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;

    if (!isDesktop) {
      return ContentShimmer.playlistShimmer(context);
    }
    final leftWidth = screenWidth * 0.42;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftWidth,
          child: Container(
            margin: const EdgeInsets.all(AppDimens.spacingLg),
            decoration: BoxDecoration(
              color: MainScreenColors.getSurfaceColor(isDarkMode),
              borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.paddingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    highlightColor: isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[100]!,
                    child: Container(
                      width: AppDimens.headerImageMd + AppDimens.spacingXxl,
                      height: AppDimens.headerImageMd + AppDimens.spacingXxl,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXl),
                  Shimmer.fromColors(
                    baseColor: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    highlightColor: isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[100]!,
                    child: Container(
                      height: 28,
                      width: leftWidth * 0.8,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingS),
                  Shimmer.fromColors(
                    baseColor: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    highlightColor: isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[100]!,
                    child: Container(
                      height: 16,
                      width: leftWidth * 0.6,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXl),
                  Shimmer.fromColors(
                    baseColor: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    highlightColor: isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[100]!,
                    child: Container(
                      height: 44,
                      width: leftWidth * 0.9,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: AppDimens.borderWidthThin,
          height: double.infinity,
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.08),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: AppDimens.miniPlayerHeight + AppDimens.spacingXs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContentShimmer.buildSectionHeaderShimmer(context, 'Songs'),
                ContentShimmer.buildSongListShimmer(context, 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
