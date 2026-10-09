import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/player_provider.dart';
import '../../core/providers/settings_provider.dart';

class ContentShimmer {
  static Widget albumShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget artistContentShimmer(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final hasPlayer =
            playerProvider.currentSong != null ||
            playerProvider.lastPlayedSong != null;

        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildArtistHeaderShimmer(context),
                  buildSectionHeaderShimmer(context, 'Popular Songs'),
                  buildSongListShimmer(context, 5),
                  buildSectionHeaderShimmer(context, 'Albums'),
                  buildHorizontalListShimmer(context),
                  buildSectionHeaderShimmer(context, 'Singles'),
                  buildHorizontalListShimmer(context),
                  buildSectionHeaderShimmer(context, 'Similar Artists'),
                  buildGridShimmer(context),
                  SizedBox(height: hasPlayer ? 100 : 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget buildSectionHeaderShimmer(BuildContext context, String title) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Provider.of<SettingsProvider>(
                context,
                listen: false,
              ).accentColor,
            ),
          ),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
            child: Container(
              width: 60,
              height: 24,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildHorizontalListShimmer(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildGridShimmer(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static Widget buildSongListShimmer(BuildContext context, int count) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Shimmer.fromColors(
          baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildArtistHeaderShimmer(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: MainScreenColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MainScreenColors.getPrimaryColor(
                isDarkMode,
              ).withValues(alpha: 0.2),
              MainScreenColors.getSecondaryColor(
                isDarkMode,
              ).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor: isDarkMode
                          ? Colors.grey[600]!
                          : Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor: isDarkMode
                          ? Colors.grey[600]!
                          : Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            highlightColor: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[100]!,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: 40,
                                height: 40,
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
            ],
          ),
        ),
      ),
    );
  }

  static Widget playlistShimmer(BuildContext context) {
    return Column(
      children: [
        _buildPlaylistHeaderShimmer(context),
        Expanded(child: albumShimmer(context)),
      ],
    );
  }

  static Widget _buildPlaylistHeaderShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: MainScreenColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MainScreenColors.getPrimaryColor(
                isDarkMode,
              ).withValues(alpha: 0.2),
              MainScreenColors.getSecondaryColor(
                isDarkMode,
              ).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                highlightColor: isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[100]!,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor: isDarkMode
                          ? Colors.grey[600]!
                          : Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: isDarkMode
                          ? Colors.grey[800]!
                          : Colors.grey[300]!,
                      highlightColor: isDarkMode
                          ? Colors.grey[600]!
                          : Colors.grey[100]!,
                      child: Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[700]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            highlightColor: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[100]!,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[800]!
                                  : Colors.grey[300]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: 40,
                                height: 40,
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
            ],
          ),
        ),
      ),
    );
  }
}
