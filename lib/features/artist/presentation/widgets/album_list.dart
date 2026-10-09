import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../playlist_album_content/presentation/screens/playlist_album_content_screen.dart';

class AlbumListScreen extends StatelessWidget {
  final String title;
  final List<dynamic> albums;

  const AlbumListScreen({Key? key, required this.title, required this.albums})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;

    return Theme(
      data: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: MainScreenColors.getBackgroundColor(
          isDarkMode,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          elevation: AppDimens.elevationNone,
          iconTheme: IconThemeData(color: accentColor),
          titleTextStyle: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
        ),
      ),
      child: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final hasPlayer =
              playerProvider.currentSong != null ||
              playerProvider.lastPlayedSong != null;

          return SafeArea(
            top: false,
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
                title: Text(
                  title,
                  style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
                ),
                leading: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(AppDimens.paddingSm),
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(isDarkMode),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    child: Icon(Icons.arrow_back, color: accentColor),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount = 2;
                      if (width >= 1200) {
                        crossAxisCount = 5;
                      } else if (width >= 1000) {
                        crossAxisCount = 4;
                      } else if (width >= 700) {
                        crossAxisCount = 3;
                      }

                      final childAspectRatio = width >= 1000 ? 0.8 : 0.75;

                      return GridView.builder(
                        padding: EdgeInsets.only(
                          left: AppDimens.paddingLg,
                          right: AppDimens.paddingLg,
                          top: AppDimens.paddingLg,
                          bottom: hasPlayer
                              ? (AppDimens.miniPlayerHeightWide +
                                    AppDimens.spacingXxxl)
                              : AppDimens.paddingLg,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: AppDimens.spacingXxl,
                          mainAxisSpacing: AppDimens.spacingXxl,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (context, index) => Container(
                          decoration: BoxDecoration(
                            color: MainScreenColors.getSurfaceColor(isDarkMode),
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusLg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 5,
                                offset: Offset(0, AppDimens.elevationLow),
                              ),
                            ],
                          ),
                          child: AlbumCard(album: albums[index]),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  final dynamic album;

  const AlbumCard({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistAlbumContent(content: album),
        ),
      ),
      child: Container(
        width: AppDimens.shimmerGridItem,
        decoration: BoxDecoration(
          color: MainScreenColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusLg),
              ),
              child: CachedNetworkImage(
                imageUrl: album.thumbnails.last.url,
                height: AppDimens.headerImageMd,
                width: AppDimens.shimmerGridItem,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                  child: Icon(
                    Icons.error,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: AppTextStyles.bodyMd(
                      isDarkMode: isDarkMode,
                    ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    album.artist.name,
                    style: AppTextStyles.settingsSubtitle(
                      isDarkMode: isDarkMode,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
