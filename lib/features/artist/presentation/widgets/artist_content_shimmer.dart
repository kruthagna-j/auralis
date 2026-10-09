import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/components/content_details_shimmer.dart';

class ArtistContentShimmer {
  static const double _desktopBreakpoint = AppDimens.breakpointDesktop;
  static Widget headerShimmer(BuildContext context) {
    final isDarkMode =
        Provider.of<SettingsProvider>(context, listen: false).themeMode ==
        ThemeMode.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    if (isDesktop) {
      final imageSize = AppDimens.headerImageMd + AppDimens.spacingXxl;
      return Container(
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingXl),
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                child: Container(
                  height: 28,
                  width: screenWidth * 0.3,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
              const SizedBox(height: AppDimens.spacingS),
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                child: Container(
                  height: 16,
                  width: screenWidth * 0.22,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                ),
              ),
              const SizedBox(height: AppDimens.spacingXl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: isDarkMode
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    highlightColor: isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[100]!,
                    child: Container(
                      height: 48,
                      width: 200,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingLg),
                  ...List.generate(
                    2,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Shimmer.fromColors(
                        baseColor: isDarkMode
                            ? Colors.grey[800]!
                            : Colors.grey[300]!,
                        highlightColor: isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey[100]!,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return ContentShimmer.buildArtistHeaderShimmer(context);
  }

  static Widget pageShimmer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _desktopBreakpoint;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenWidth * 0.38,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: AppDimens.miniPlayerHeight + AppDimens.spacingXs,
              ),
              child: headerShimmer(context),
            ),
          ),
          Container(
            width: AppDimens.borderWidthThin,
            height: double.infinity,
            color: MainScreenColors.getTextColor(
              Provider.of<SettingsProvider>(context, listen: false).themeMode ==
                  ThemeMode.dark,
            ).withValues(alpha: 0.1),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: AppDimens.miniPlayerHeight + AppDimens.spacingXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'popular_songs'.tr(),
                  ),
                  ContentShimmer.buildSongListShimmer(context, 5),
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'albums'.tr(),
                  ),
                  ContentShimmer.buildHorizontalListShimmer(context),
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'singles'.tr(),
                  ),
                  ContentShimmer.buildHorizontalListShimmer(context),
                  ContentShimmer.buildSectionHeaderShimmer(
                    context,
                    'similar_artists'.tr(),
                  ),
                  ContentShimmer.buildGridShimmer(context),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ContentShimmer.artistContentShimmer(context);
  }
}
