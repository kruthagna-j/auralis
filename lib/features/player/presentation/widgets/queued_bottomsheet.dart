import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import 'music_search.dart';
import '../../../../shared/components/app_snackbar.dart';

class QueueBottomSheet extends StatefulWidget {
  const QueueBottomSheet({Key? key}) : super(key: key);

  @override
  State<QueueBottomSheet> createState() => _QueueBottomSheetState();
}

class _QueueBottomSheetState extends State<QueueBottomSheet> {
  ScrollController? _sheetScrollController;
  bool _scrolledToCurrent = false;

  Future<void> _showClearQueueDialog(
    BuildContext context,
    bool isDarkMode,
    Color accentColor,
    QueueProvider queueProvider,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: accentColor),
            const SizedBox(width: AppDimens.spacingSmMd),
            Text(
              'Clear Queue?',
              style: AppTextStyles.subtitle(
                isDarkMode: isDarkMode,
                color: MainScreenColors.getTextColor(isDarkMode),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to clear the current queue?',
          style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingLg,
          vertical: AppDimens.paddingSm,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: MainScreenColors.getTextColor(isDarkMode),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingXl,
                vertical: AppDimens.spacingSmMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
            ),
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingXl,
                vertical: AppDimens.spacingSmMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              ),
              elevation: 0,
            ),
            child: const Text('Clear'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      queueProvider.clearQueue();
      AppSnackBar.showInfo(context, 'Queue cleared successfully');
    }
  }

  void _maybeScrollToCurrent(QueueProvider queueProvider) {
    if (_scrolledToCurrent) return;
    final currentIndex = queueProvider.currentIndex;
    final queue = queueProvider.queue;
    if (queue.isEmpty) return;
    if (currentIndex < 0 || currentIndex >= queue.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final song = queue[currentIndex];
      final itemKey = GlobalObjectKey('queue_item_${song.videoId}');
      final ctx = itemKey.currentContext;
      if (ctx != null) {
        try {
          Scrollable.ensureVisible(
            ctx,
            duration: AppDimens.animDefault,
            alignment: 0.5,
            curve: Curves.easeInOut,
          );
          _scrolledToCurrent = true;
          return;
        } catch (_) {}
      }

      if (_sheetScrollController != null &&
          _sheetScrollController!.hasClients) {
        final itemExtent = AppDimens.miniPlayerHeight;
        final offset = (currentIndex * itemExtent).clamp(
          0.0,
          _sheetScrollController!.position.maxScrollExtent,
        );
        try {
          _sheetScrollController!.animateTo(
            offset,
            duration: AppDimens.animDefault,
            curve: Curves.easeInOut,
          );
          _scrolledToCurrent = true;
        } catch (_) {}
      }
    });
  }

  Widget _buildThumbnail(dynamic song, QueueProvider queueProvider) {
    final playlistId = queueProvider.playlistId;
    final thumbnailUrl = song.thumbnails.first.url;

    if (playlistId == 'local_music') {
      if (thumbnailUrl.isNotEmpty) {
        final file = File(thumbnailUrl.replaceFirst('file://', ''));
        return Image.file(
          file,
          width: AppDimens.thumbnailDefault,
          height: AppDimens.thumbnailDefault,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/default_artwork.png',
              width: AppDimens.thumbnailDefault,
              height: AppDimens.thumbnailDefault,
              fit: BoxFit.cover,
            );
          },
        );
      } else {
        return Image.asset(
          'assets/default_artwork.png',
          width: AppDimens.thumbnailDefault,
          height: AppDimens.thumbnailDefault,
          fit: BoxFit.cover,
        );
      }
    } else {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl,
        width: AppDimens.thumbnailDefault,
        height: AppDimens.thumbnailDefault,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          'assets/default_artwork.png',
          width: AppDimens.thumbnailDefault,
          height: AppDimens.thumbnailDefault,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/default_artwork.png',
          width: AppDimens.thumbnailDefault,
          height: AppDimens.thumbnailDefault,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  BoxDecoration _buildBackgroundDecoration(
    Color backgroundColor,
    bool isDarkMode,
  ) {
    return BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.08),
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusXxl),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: AppDimens.opacityMedium),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final playerService = Provider.of<PlayerProvider>(
      context,
      listen: false,
    ).playerService;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ValueListenableBuilder<Color>(
        valueListenable: playerService.backgroundColorNotifier,
        builder: (context, backgroundColor, child) => Consumer<QueueProvider>(
          builder: (context, queueProvider, child) {
            _sheetScrollController ??= scrollController;

            _maybeScrollToCurrent(queueProvider);

            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusXxl),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: _buildBackgroundDecoration(
                    backgroundColor,
                    isDarkMode,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: AppDimens.dragHandleWidth,
                        height: AppDimens.dragHandleHeight,
                        margin: const EdgeInsets.symmetric(
                          vertical: AppDimens.spacingSm,
                        ),
                        decoration: BoxDecoration(
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusXs,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingLg,
                          vertical: AppDimens.spacingS,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.queue_music,
                                  color: accentColor,
                                  size: AppDimens.iconMd,
                                ),
                                const SizedBox(width: AppDimens.paddingSm),
                                Text(
                                  'Playing',
                                  style: AppTextStyles.titleSm(
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppDimens.spacingSmMd,
                                    vertical: AppDimens.paddingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(
                                      alpha: AppDimens.opacityMedium,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusXl,
                                    ),
                                  ),
                                  child: Text(
                                    '${queueProvider.queue.isEmpty ? 0 : queueProvider.currentIndex + 1} / ${queueProvider.queue.length} tracks',
                                    style: AppTextStyles.chipLabel(
                                      isDarkMode: isDarkMode,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'More',
                                  color: MainScreenColors.getSurfaceColor(
                                    isDarkMode,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMd,
                                    ),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'search') {
                                      showSearch(
                                        context: context,
                                        delegate: MusicSearch(
                                          accentColor: accentColor,
                                        ),
                                      );
                                      return;
                                    }

                                    if (value == 'clear_queue') {
                                      _showClearQueueDialog(
                                        context,
                                        isDarkMode,
                                        accentColor,
                                        queueProvider,
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem<String>(
                                      value: 'search',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ),
                                            size: AppDimens.iconSm,
                                          ),
                                          const SizedBox(
                                            width: AppDimens.spacingSmMd,
                                          ),
                                          Text(
                                            'Search',
                                            style: AppTextStyles.bodyMd(
                                              isDarkMode: isDarkMode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'clear_queue',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_sweep_outlined,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ),
                                            size: AppDimens.iconSm,
                                          ),
                                          const SizedBox(
                                            width: AppDimens.spacingSmMd,
                                          ),
                                          Text(
                                            'Clear Queue',
                                            style: AppTextStyles.bodyMd(
                                              isDarkMode: isDarkMode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    width: AppDimens.buttonSizeCompact,
                                    height: AppDimens.buttonSizeCompact,
                                    margin: const EdgeInsets.only(
                                      left: AppDimens.spacingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusMd,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppDimens.spacingS,
                                      ),
                                      child: Icon(
                                        Icons.more_vert,
                                        color: accentColor,
                                        size: AppDimens.iconSm,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: AppDimens.opacityLight),
                      ),
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          physics: const ClampingScrollPhysics(),
                          scrollController: scrollController,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex--;
                            queueProvider.reorderQueue(oldIndex, newIndex);
                          },
                          itemCount: queueProvider.queue.length,
                          itemBuilder: (context, index) {
                            final song = queueProvider.queue[index];
                            final isPlaying =
                                index == queueProvider.currentIndex;

                            return Dismissible(
                              key: ValueKey(song.videoId),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                  right: AppDimens.spacingXl,
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXxl,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: accentColor,
                                        ),
                                        const SizedBox(
                                          width: AppDimens.spacingSmMd,
                                        ),
                                        Text(
                                          'Remove from Queue?',
                                          style: AppTextStyles.subtitle(
                                            isDarkMode: isDarkMode,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'Are you sure you want to remove this track from the queue?',
                                      style: AppTextStyles.subtitle(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                    actionsPadding: const EdgeInsets.symmetric(
                                      horizontal: AppDimens.paddingLg,
                                      vertical: AppDimens.paddingSm,
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              MainScreenColors.getTextColor(
                                                isDarkMode,
                                              ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppDimens.spacingXl,
                                            vertical: AppDimens.spacingSmMd,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusLg,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Cancel'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accentColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppDimens.spacingXl,
                                            vertical: AppDimens.spacingSmMd,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusLg,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text('Delete'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );
                                if (result == true) {
                                  queueProvider.removeFromQueue(index);
                                  return true;
                                }
                                return false;
                              },
                              child: Container(
                                key: GlobalObjectKey(
                                  'queue_item_${song.videoId}',
                                ),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? accentColor.withValues(alpha: 0.2)
                                      : null,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    leading: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusSm,
                                          ),
                                          child: _buildThumbnail(
                                            song,
                                            queueProvider,
                                          ),
                                        ),
                                        if (isPlaying)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppDimens.radiusSm,
                                                    ),
                                              ),
                                              child: Icon(
                                                Icons.equalizer,
                                                color: accentColor,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Text(
                                      song.name,
                                      style: isPlaying
                                          ? AppTextStyles.queueItemPlaying(
                                              isDarkMode: isDarkMode,
                                              accentColor: accentColor,
                                            )
                                          : AppTextStyles.queueItem(
                                              isDarkMode: isDarkMode,
                                            ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song.artists
                                          .map((artist) => artist.name)
                                          .join(', '),
                                      style: AppTextStyles.settingsSubtitle(
                                        isDarkMode: isDarkMode,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove_circle_outline,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ).withValues(
                                                  alpha: AppDimens.opacityMuted,
                                                ),
                                          ),
                                          onPressed: () => queueProvider
                                              .removeFromQueue(index),
                                        ),
                                        ReorderableDragStartListener(
                                          index: index,
                                          child: Icon(
                                            Icons.drag_handle,
                                            color:
                                                MainScreenColors.getTextColor(
                                                  isDarkMode,
                                                ).withValues(
                                                  alpha: AppDimens.opacityMuted,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      final playerProvider =
                                          Provider.of<PlayerProvider>(
                                            context,
                                            listen: false,
                                          );

                                      final playlistId =
                                          queueProvider.playlistId;

                                      if (playlistId == 'local_music') {
                                        queueProvider.setCurrentIndex(index);

                                        final localContainer =
                                            playerProvider.currentLocalSong;
                                        final localQueue =
                                            localContainer != null
                                            ? (localContainer['queue']
                                                  as List<
                                                    Map<String, dynamic>
                                                  >?)
                                            : null;

                                        if (localQueue != null &&
                                            index < localQueue.length) {
                                          final localSong = localQueue[index];

                                          playerProvider.updateCurrentLocalSong(
                                            localSong,
                                          );

                                          if (playerProvider
                                                  .playerService
                                                  .audioPlayerInstance !=
                                              null) {
                                            await playerProvider
                                                .playerService
                                                .audioPlayerInstance!
                                                .seek(
                                                  Duration.zero,
                                                  index: index,
                                                );
                                          } else {
                                            final localPath =
                                                localSong['localPath'];
                                            if (localPath != null) {
                                              try {
                                                await playerProvider
                                                    .playerService
                                                    .playLocalAudioWithQueue(
                                                      localPath,
                                                      localSong,
                                                      localQueue,
                                                      index,
                                                    );
                                              } catch (e) {
                                                AppSnackBar.showError(
                                                  context,
                                                  'Failed to play song',
                                                );
                                                playerProvider.playerService
                                                    .playNext();
                                              }
                                            }
                                          }
                                        } else {
                                          AppSnackBar.showWarning(
                                            context,
                                            'Local queue data not available',
                                          );
                                        }
                                      } else {
                                        // queueProvider.setCurrentIndex(index);
                                        await playerProvider.playerService
                                            .playSong(song);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
