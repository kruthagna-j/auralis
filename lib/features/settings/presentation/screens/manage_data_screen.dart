import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:terminate_restart/terminate_restart.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/stats_provider.dart';
import '../../../../shared/components/app_snackbar.dart';
import '../../data/services/data_management_service.dart';
import '../widgets/settings_item.dart';

class ManageDataScreen extends StatefulWidget {
  const ManageDataScreen({Key? key}) : super(key: key);

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final DataManagementService _dataManagementService = DataManagementService();
  Map<String, DataUsageStats> _actionStats = const {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _refreshActionStats();
  }

  Future<void> _refreshActionStats() async {
    if (mounted) {
      setState(() => _isLoadingStats = true);
    }

    final stats = await _dataManagementService.getClearActionStats();
    if (!mounted) {
      return;
    }

    setState(() {
      _actionStats = stats;
      _isLoadingStats = false;
    });
  }

  Future<void> _runClearAction(Future<void> Function() action) async {
    await action();
    await _refreshActionStats();
  }

  String _statLabel(String key) {
    if (_isLoadingStats) {
      return 'Loading...';
    }
    final stats = _actionStats[key] ?? DataUsageStats.empty;
    return _formatStat(stats);
  }

  String _formatStat(DataUsageStats stat) {
    if (stat.isEmpty) {
      return 'Empty';
    }

    final hasItems = stat.itemCount > 0;
    final hasBytes = stat.sizeBytes > 0;

    if (hasItems && hasBytes) {
      return '${stat.itemCount} items, ${_formatBytes(stat.sizeBytes)}';
    }
    if (hasItems) {
      return '${stat.itemCount} items';
    }
    return _formatBytes(stat.sizeBytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? MainScreenColors.darkBackgroundColor
            : MainScreenColors.lightBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.transparent
              : MainScreenColors.getSurfaceColor(false),
          elevation: 0,
          title: Text(
            'manage_data'.tr(),
            style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: MainScreenColors.getTextColor(isDarkMode),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshActionStats,
          color: accentColor,
          backgroundColor: isDarkMode
              ? MainScreenColors.darkSurfaceColor
              : MainScreenColors.lightSurfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimens.paddingLg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final int columns = width >= 1200 ? 3 : (width >= 900 ? 2 : 1);
                const spacing = AppDimens.spacingLg;
                final columnWidth = columns == 1
                    ? double.infinity
                    : (width - (columns - 1) * spacing) / columns;

                final primaryActions = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsItem(
                      icon: Icons.cleaning_services,
                      title: 'clear_cache'.tr(),
                      subtitle: _statLabel('clear_cache'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Cache',
                        message: 'clear_cache_card_description'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearCache(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'cache_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.playlist_play,
                      title: 'clear_created_playlists'.tr(),
                      subtitle: _statLabel('clear_created_playlists'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Created Playlists',
                        message: 'clear_created_playlists_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () =>
                                _dataManagementService.clearCreatedPlaylists(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'created_playlists_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.album,
                      title: 'clear_saved_albums'.tr(),
                      subtitle: _statLabel('clear_saved_albums'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Saved Albums',
                        message: 'clear_saved_albums_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearSavedAlbums(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'saved_albums_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.playlist_add,
                      title: 'clear_saved_playlists'.tr(),
                      subtitle: _statLabel('clear_saved_playlists'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Saved Playlists',
                        message: 'clear_saved_playlists_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearSavedPlaylists(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'saved_playlists_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.person,
                      title: 'clear_favorite_artists'.tr(),
                      subtitle: _statLabel('clear_favorite_artists'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Favorite Artists',
                        message: 'clear_favorite_artists_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearFavoriteArtists(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'favorite_artists_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.favorite,
                      title: 'clear_liked_songs'.tr(),
                      subtitle: _statLabel('clear_liked_songs'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Liked Songs',
                        message: 'clear_liked_songs_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearLikedSongs(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'liked_songs_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.history,
                      title: 'clear_playback_history'.tr(),
                      subtitle: _statLabel('clear_playback_history'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Playback History',
                        message: 'clear_playback_history_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearLastPlayed(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'playback_history_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.search,
                      title: 'clear_search_history'.tr(),
                      subtitle: _statLabel('clear_search_history'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Search History',
                        message: 'clear_search_history_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearSearchHistory(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'search_history_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.wifi_tethering_off,
                      title: 'clear_audio_url_cache'.tr(),
                      subtitle: _statLabel('clear_audio_url_cache'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Audio URL Cache',
                        message: 'clear_audio_url_cache_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearAudioUrlCache(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'audio_url_cache_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.sd_storage,
                      title: 'clear_temp_audio_cache'.tr(),
                      subtitle: _statLabel('clear_temp_audio_cache'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Audio Cache',
                        message: 'clear_temp_audio_cache_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearTempAudioCache(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'temp_audio_cache_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.library_music,
                      title: 'clear_playlist_songs'.tr(),
                      subtitle: _statLabel('clear_playlist_songs'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Playlist Songs',
                        message: 'clear_playlist_songs_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearPlaylistSongs(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'playlist_songs_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.info,
                      title: 'clear_video_info_cache'.tr(),
                      subtitle: _statLabel('clear_video_info_cache'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Video Info Cache',
                        message: 'clear_video_info_cache_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearVideoInfoCache(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'video_info_cache_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.queue_music,
                      title: 'clear_queue'.tr(),
                      subtitle: _statLabel('clear_queue'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Queue',
                        message: 'clear_queue_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearQueue(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'queue_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.analytics,
                      title: 'clear_playback_stats'.tr(),
                      subtitle: _statLabel('clear_playback_stats'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Playback Stats',
                        message: 'clear_playback_stats_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(() async {
                            await _dataManagementService.clearPlaybackStats();
                            final statsProvider = Provider.of<StatsProvider>(
                              context,
                              listen: false,
                            );
                            await statsProvider.clearAllStats();
                          });
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'playback_stats_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                    SettingsItem(
                      icon: Icons.playlist_play,
                      title: 'clear_recent_playlists'.tr(),
                      subtitle: _statLabel('clear_recent_playlists'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear Recent Playlists',
                        message: 'clear_recent_playlists_message'.tr(),
                        onConfirm: () async {
                          await _runClearAction(
                            () => _dataManagementService.clearRecentplaylists(),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          AppSnackBar.showSuccess(
                            context,
                            'recent_playlists_cleared_success'.tr(),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                  ],
                );

                final appDataSection = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.spacingXs,
                        AppDimens.spacingXxl,
                        AppDimens.spacingXs,
                        AppDimens.spacingMd,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever,
                            color: accentColor,
                            size: AppDimens.iconMdLg,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'app_data'.tr(),
                            style: AppTextStyles.sectionHeader(
                              accentColor: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SettingsItem(
                      icon: Icons.delete_forever,
                      title: 'clear_all_app_data'.tr(),
                      subtitle: _statLabel('clear_all_app_data'),
                      onTap: () => _showModernConfirmationDialog(
                        context: context,
                        title: 'Clear All App Data',
                        message: 'clear_all_app_data_message'.tr(),
                        onConfirm: () async {
                          await _dataManagementService.clearAllAppData();
                          await _dataManagementService.clearAllHiveData();

                          await TerminateRestart.instance.restartApp(
                            options: const TerminateRestartOptions(
                              terminate: true,
                              clearData: true,
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                        accentColor: accentColor,
                      ),
                      isDarkMode: isDarkMode,
                      accentColor: accentColor,
                    ),
                  ],
                );

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(width: columnWidth, child: primaryActions),
                    SizedBox(width: columnWidth, child: appDataSection),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

void _showModernConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  required bool isDarkMode,
  required Color accentColor,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode
          ? MainScreenColors.darkSurfaceColor
          : MainScreenColors.lightSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      title: Text(title, style: AppTextStyles.titleSm(isDarkMode: isDarkMode)),
      content: Text(
        message,
        style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'cancel'.tr(),
            style: AppTextStyles.subtitle(
              isDarkMode: isDarkMode,
              color: accentColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await onConfirm();
          },
          child: Text(
            'confirm_button'.tr(),
            style: AppTextStyles.button(color: accentColor),
          ),
        ),
      ],
    ),
  );
}
