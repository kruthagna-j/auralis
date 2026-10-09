import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/content_router.dart';
import '../../data/search_screen_services.dart';

class SearchResultsView extends StatelessWidget {
  final TabController tabController;
  final SearchMode searchMode;
  final Map<String, List<dynamic>> categorizedResults;
  final bool isDarkMode;
  final Color accentColor;
  final ValueChanged<dynamic> onSongTapped;
  final Function(dynamic) createSongWrapper;

  const SearchResultsView({
    Key? key,
    required this.tabController,
    required this.searchMode,
    required this.categorizedResults,
    required this.isDarkMode,
    required this.accentColor,
    required this.onSongTapped,
    required this.createSongWrapper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (searchMode == SearchMode.youtube) {
      return TabBarView(
        controller: tabController,
        children: [
          _buildVideosList(categorizedResults['Videos'] ?? [], context),
        ],
      );
    } else {
      return TabBarView(
        controller: tabController,
        children: [
          _buildSongsList(categorizedResults['Songs'] ?? [], context),
          _buildContentList(
            categorizedResults['Albums'] ?? [],
            'album',
            context,
          ),
          _buildContentList(
            categorizedResults['Artists'] ?? [],
            'artist',
            context,
          ),
          _buildContentList(
            categorizedResults['Playlists'] ?? [],
            'playlist',
            context,
          ),
        ],
      );
    }
  }

  Widget _buildSongsList(List<dynamic> songs, BuildContext context) {
    final isDesktop = AppDimens.isDesktop(context);
    final maxWidth = isDesktop ? AppDimens.maxContentWidth : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppDimens.paddingXxl : 0,
            vertical: AppDimens.spacingSm,
          ),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final thumbnailUrl = song.thumbnails.isNotEmpty
                ? song.thumbnails.first.url
                : '';
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: 0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingLg,
                vertical: 0,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: AppDimens.shimmerListTile,
                  height: AppDimens.shimmerListTile,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: MainScreenColors.getSurfaceColor(isDarkMode),
                    child: Center(
                      child: CircularProgressIndicator(color: accentColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: MainScreenColors.getSurfaceColor(isDarkMode),
                    child: Icon(
                      Icons.music_note,
                      color: MainScreenColors.getTextColor(isDarkMode),
                    ),
                  ),
                ),
              ),
              title: Text(
                song.name,
                style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist.name,
                style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSongTapped(song),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideosList(List<dynamic> videos, BuildContext context) {
    final isDesktop = AppDimens.isDesktop(context);
    final maxWidth = isDesktop ? AppDimens.maxContentWidth : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppDimens.paddingXxl : 0,
            vertical: AppDimens.spacingSm,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final songWrapper = createSongWrapper(video);

            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: 0),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimens.paddingLg,
                vertical: 0,
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnails.lowResUrl,
                  width: AppDimens.shimmerListTile,
                  height: AppDimens.shimmerListTile,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: MainScreenColors.getSurfaceColor(isDarkMode),
                    child: Center(
                      child: CircularProgressIndicator(color: accentColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: MainScreenColors.getSurfaceColor(isDarkMode),
                    child: Icon(
                      Icons.music_note,
                      color: MainScreenColors.getTextColor(isDarkMode),
                    ),
                  ),
                ),
              ),
              title: Text(
                video.title,
                style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                video.author,
                style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSongTapped(songWrapper),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentList(
    List<dynamic> items,
    String type,
    BuildContext context,
  ) {
    final isDesktop = AppDimens.isDesktop(context);
    final isTablet = AppDimens.isTablet(context);
    final isMobile = AppDimens.isMobile(context);
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 3;
    } else if (isTablet && !isMobile) {
      crossAxisCount = 2;
    }

    final maxWidth = isDesktop ? AppDimens.maxContentWidth : double.infinity;
    if (crossAxisCount == 1) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: AppDimens.spacingSm),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _buildContentListItem(items[index], type, context);
            },
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GridView.builder(
          padding: EdgeInsets.all(
            isDesktop ? AppDimens.paddingXxl : AppDimens.paddingLg,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppDimens.spacingLg,
            mainAxisSpacing: AppDimens.spacingLg,
            childAspectRatio: 3.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildContentGridItem(items[index], type, context);
          },
        ),
      ),
    );
  }

  Widget _buildContentListItem(
    dynamic item,
    String type,
    BuildContext context,
  ) {
    final thumbnailUrl = item.thumbnails.isNotEmpty
        ? item.thumbnails.first.url
        : '';
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingLg,
        vertical: 0,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(
          type == 'artist' ? AppDimens.radiusAvatar : AppDimens.radiusSm,
        ),
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          width: AppDimens.shimmerListTile,
          height: AppDimens.shimmerListTile,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: MainScreenColors.getSurfaceColor(isDarkMode),
            child: Center(child: CircularProgressIndicator(color: accentColor)),
          ),
          errorWidget: (context, url, error) => Container(
            color: MainScreenColors.getSurfaceColor(isDarkMode),
            child: Icon(
              Icons.image_not_supported_outlined,
              color: MainScreenColors.getTextColor(isDarkMode),
            ),
          ),
        ),
      ),
      title: Text(
        item.name,
        style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        type.toUpperCase(),
        style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.5),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ContentRouter(content: item)),
        );
      },
    );
  }

  Widget _buildContentGridItem(
    dynamic item,
    String type,
    BuildContext context,
  ) {
    final thumbnailUrl = item.thumbnails.isNotEmpty
        ? item.thumbnails.first.url
        : '';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ContentRouter(content: item)),
        );
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingSm),
        decoration: BoxDecoration(
          color: MainScreenColors.getSurfaceColor(
            isDarkMode,
          ).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                type == 'artist' ? AppDimens.radiusAvatar : AppDimens.radiusSm,
              ),
              child: CachedNetworkImage(
                imageUrl: thumbnailUrl,
                width: AppDimens.shimmerListTile,
                height: AppDimens.shimmerListTile,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: MainScreenColors.getSurfaceColor(isDarkMode),
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: MainScreenColors.getSurfaceColor(isDarkMode),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: MainScreenColors.getTextColor(isDarkMode),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.spacingXxs),
                  Text(
                    type.toUpperCase(),
                    style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.5),
                    ),
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
