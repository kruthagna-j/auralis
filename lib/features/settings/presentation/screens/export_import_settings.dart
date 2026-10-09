import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/favorite_artist_provider.dart';
import '../../../playlists/data/providers/playlist_album_library_provider.dart';
import '../../data/services/export_import_settings_service.dart';
import '../widgets/settings_item.dart';
import '../../../../shared/components/app_snackbar.dart';

class ExportImportSettingsScreen extends StatefulWidget {
  const ExportImportSettingsScreen({Key? key}) : super(key: key);

  @override
  _ExportImportSettingsScreenState createState() =>
      _ExportImportSettingsScreenState();
}

Widget _buildModernButton({
  required IconData icon,
  required String label,
  required Color accentColor,
  required bool isDarkMode,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.16),
            accentColor.withValues(alpha: 0.32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.spacingS,
        horizontal: AppDimens.spacingSmMd,
      ),
      constraints: const BoxConstraints(
        minWidth: AppDimens.thumbnailLarge,
        minHeight: AppDimens.buttonSizeCompact,
        maxWidth: AppDimens.buttonWidthMedium,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accentColor, size: AppDimens.iconXs),
          const SizedBox(width: AppDimens.spacingS),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption(
                isDarkMode: isDarkMode,
              ).copyWith(fontWeight: AppTextStyles.weightMedium),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExportImportSettingsScreenState
    extends State<ExportImportSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: true,
    );
    final accentColor = settingsProvider.accentColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.transparent
              : MainScreenColors.getSurfaceColor(false),
          elevation: 0,
          title: Text(
            'export_import_settings_title'.tr(),
            style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: MainScreenColors.getTextColor(isDarkMode),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final int columns = width >= AppDimens.breakpointExtraWide
                  ? 3
                  : (width >= AppDimens.breakpointDesktopLarge ? 2 : 1);
              const spacing = AppDimens.spacingLg;
              final columnWidth = columns == 1
                  ? double.infinity
                  : (width - (columns - 1) * spacing) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: _buildModernCard(
                      context,
                      icon: Icons.upload_file,
                      title: 'export_card_title'.tr(),
                      description: 'export_card_description'.tr(),
                      accentColor: accentColor,
                      isDarkMode: isDarkMode,
                      action: _buildModernButton(
                        icon: Icons.upload,
                        label: 'export_data_button'.tr(),
                        accentColor: accentColor,
                        isDarkMode: isDarkMode,
                        onTap: () => _showExportBottomSheet(accentColor),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: columnWidth,
                    child: _buildModernCard(
                      context,
                      icon: Icons.download,
                      title: 'import_card_title'.tr(),
                      description: 'import_card_description'.tr(),
                      accentColor: accentColor,
                      isDarkMode: isDarkMode,
                      action: _buildModernButton(
                        icon: Icons.download,
                        label: 'import_data_button'.tr(),
                        accentColor: accentColor,
                        isDarkMode: isDarkMode,
                        onTap: () => _handleDirectImport(accentColor),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color accentColor,
    required bool isDarkMode,
    Widget? action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: isDarkMode ? 0.16 : 0.10),
            MainScreenColors.getPrimaryColor(
              isDarkMode,
            ).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(AppDimens.spacingSmMd),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: AppDimens.iconMdLg,
                  ),
                ),
                const SizedBox(width: AppDimens.spacingXl),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Text(
              description,
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.82),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppDimens.spacingMd),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Color accentColor,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.16),
              accentColor.withValues(alpha: 0.32),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.spacingS,
          horizontal: AppDimens.spacingSmMd,
        ),
        constraints: const BoxConstraints(
          minWidth: AppDimens.thumbnailLarge,
          minHeight: AppDimens.buttonSizeCompact,
          maxWidth: AppDimens.buttonWidthMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: AppDimens.iconXs),
            const SizedBox(width: AppDimens.spacingS),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption(
                  isDarkMode: isDarkMode,
                ).copyWith(fontWeight: AppTextStyles.weightMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportBottomSheet(Color accentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXxl),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: _ExportBottomSheet(accentColor: accentColor),
          ),
        );
      },
    );
  }

  Future<void> _handleDirectImport(Color accentColor) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;

      if (!ExportImportSettingsService().isValidImportFile(fileName)) {
        AppSnackBar.showWarning(context, 'invalid_file_selected_snackbar'.tr());
        return;
      }

      final importData = await ExportImportSettingsService().readImportFile(
        filePath,
      );

      _showDynamicImportBottomSheet(context, importData, accentColor);
    } catch (e) {
      print('Error during import: $e');
      AppSnackBar.showError(context, 'import_failed_snackbar'.tr());
    }
  }

  void _showDynamicImportBottomSheet(
    BuildContext context,
    Map<String, dynamic> importData,
    Color accentColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXxl),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: _DynamicImportBottomSheet(
              importData: importData,
              accentColor: accentColor,
            ),
          ),
        );
      },
    );
  }
}

class _ExportBottomSheet extends StatefulWidget {
  final Color accentColor;
  const _ExportBottomSheet({Key? key, required this.accentColor})
    : super(key: key);

  @override
  _ExportBottomSheetState createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<_ExportBottomSheet> {
  bool _exportCreatedPlaylists = true;
  bool _exportSavedAlbums = true;
  bool _exportSavedPlaylists = true;
  bool _exportfavoriteArtists = true;
  bool _exportfavoriteSongs = true;
  bool _exportAppSettings = true;
  bool _exportPlaybackHistory = true;
  bool _exportPlaylistSongs = true;
  bool _exportQueue = true;
  bool _exportPlaybackStats = true;
  bool _exportRecentPlaylists = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.paddingLg,
            AppDimens.paddingLg,
            AppDimens.paddingLg,
            0,
          ),
          child: Column(
            children: [
              Text(
                'export_bottom_sheet_title'.tr(),
                style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
              ),
              const SizedBox(height: AppDimens.spacingSm),
              Text(
                'export_bottom_sheet_description'.tr(),
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppDimens.spacingSm),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleOption(
                  'created_playlists'.tr(),
                  _exportCreatedPlaylists,
                  (value) => setState(() => _exportCreatedPlaylists = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'saved_albums'.tr(),
                  _exportSavedAlbums,
                  (value) => setState(() => _exportSavedAlbums = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'saved_playlists'.tr(),
                  _exportSavedPlaylists,
                  (value) => setState(() => _exportSavedPlaylists = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'favorite_artists'.tr(),
                  _exportfavoriteArtists,
                  (value) => setState(() => _exportfavoriteArtists = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'favorite_songs'.tr(),
                  _exportfavoriteSongs,
                  (value) => setState(() => _exportfavoriteSongs = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'app_settings'.tr(),
                  _exportAppSettings,
                  (value) => setState(() => _exportAppSettings = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'playback_history'.tr(),
                  _exportPlaybackHistory,
                  (value) => setState(() => _exportPlaybackHistory = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'playlist_songs'.tr(),
                  _exportPlaylistSongs,
                  (value) => setState(() => _exportPlaylistSongs = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'queue'.tr(),
                  _exportQueue,
                  (value) => setState(() => _exportQueue = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'playback_statistics'.tr(),
                  _exportPlaybackStats,
                  (value) => setState(() => _exportPlaybackStats = value),
                  isDarkMode,
                  accentColor,
                ),
                _buildToggleOption(
                  'recent_playlists'.tr(),
                  _exportRecentPlaylists,
                  (value) => setState(() => _exportRecentPlaylists = value),
                  isDarkMode,
                  accentColor,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: _buildModernButton(
            icon: Icons.upload,
            label: 'export_selected_button'.tr(),
            accentColor: accentColor,
            isDarkMode: isDarkMode,
            onTap: () => _handleExport(context),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    Function(bool) onChanged,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SettingsToggleItem(
      icon: Icons.import_export,
      title: label,
      value: value,
      onChanged: onChanged,
      isDarkMode: isDarkMode,
      accentColor: accentColor,
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final exportData = await ExportImportSettingsService().exportSelectedData(
        exportCreatedPlaylists: _exportCreatedPlaylists,
        exportSavedAlbums: _exportSavedAlbums,
        exportSavedPlaylists: _exportSavedPlaylists,
        exportfavoriteArtists: _exportfavoriteArtists,
        exportfavoriteSongs: _exportfavoriteSongs,
        exportAppSettings: _exportAppSettings,
        exportPlaybackHistory: _exportPlaybackHistory,

        exportPlaylistSongs: _exportPlaylistSongs,
        exportQueue: _exportQueue,
        exportPlaybackStats: _exportPlaybackStats,
        exportRecentPlaylists: _exportRecentPlaylists,
      );

      if (exportData.isEmpty) {
        AppSnackBar.showWarning(
          context,
          'no_data_selected_for_export_snackbar'.tr(),
        );
        return;
      }

      final filePath = await ExportImportSettingsService().createExportFile(
        exportData,
      );

      await SharePlus.instance.share(
        ShareParams(text: 'Auralis export file', files: [XFile(filePath)]),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error during export: $e');
      AppSnackBar.showError(context, 'export_failed_snackbar'.tr());
    }
  }
}

class _DynamicImportBottomSheet extends StatefulWidget {
  final Map<String, dynamic> importData;
  final Color accentColor;

  const _DynamicImportBottomSheet({
    Key? key,
    required this.importData,
    required this.accentColor,
  }) : super(key: key);

  @override
  _DynamicImportBottomSheetState createState() =>
      _DynamicImportBottomSheetState();
}

class _DynamicImportBottomSheetState extends State<_DynamicImportBottomSheet> {
  Map<String, bool> _selectedItems = {};
  Map<String, bool> _availableItems = {};
  Map<String, int> _itemCounts = {};

  @override
  void initState() {
    super.initState();
    final service = ExportImportSettingsService();
    _availableItems = service.detectAvailableDataTypes(widget.importData);
    _itemCounts = service.getDataTypeCounts(widget.importData);

    _selectedItems = Map.fromEntries(
      _availableItems.entries.map((e) => MapEntry(e.key, true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.paddingLg,
            AppDimens.paddingLg,
            AppDimens.paddingLg,
            0,
          ),
          child: Column(
            children: [
              Text(
                'Select Data to Import',
                style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
              ),
              const SizedBox(height: AppDimens.spacingSm),
              Text(
                'Choose which data types from the file you want to import',
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppDimens.spacingSm),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [..._buildDynamicOptions(isDarkMode, accentColor)],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: _buildModernButton(
            icon: Icons.download,
            label: 'Import Selected Data',
            accentColor: accentColor,
            isDarkMode: isDarkMode,
            onTap: () => _handleDynamicImport(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicOptions(bool isDarkMode, Color accentColor) {
    final optionNames = {
      'createdPlaylists': 'created_playlists'.tr(),
      'savedAlbums': 'saved_albums'.tr(),
      'savedPlaylists': 'saved_playlists'.tr(),
      'favoriteArtists': 'favorite_artists'.tr(),
      'favoriteSongs': 'favorite_songs'.tr(),
      'appSettings': 'app_settings'.tr(),
      'playbackHistory': 'playback_history'.tr(),
      'playlistSongs': 'playlist_songs'.tr(),
      'queue': 'queue'.tr(),
      'playbackStats': 'playback_statistics'.tr(),
      'recentPlaylists': 'recent_playlists'.tr(),
    };

    return _availableItems.entries.where((entry) => entry.value).map((entry) {
      final key = entry.key;
      final count = _itemCounts[key] ?? 0;
      final title = '${optionNames[key]} ($count items)';

      return _buildToggleOption(
        title,
        _selectedItems[key] ?? false,
        (value) => setState(() => _selectedItems[key] = value),
        isDarkMode,
        accentColor,
      );
    }).toList();
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    Function(bool) onChanged,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SettingsToggleItem(
      icon: Icons.import_export,
      title: label,
      value: value,
      onChanged: onChanged,
      isDarkMode: isDarkMode,
      accentColor: accentColor,
    );
  }

  Future<void> _handleDynamicImport(BuildContext context) async {
    try {
      await ExportImportSettingsService().importSelectedData(
        importData: widget.importData,
        importCreatedPlaylists: _selectedItems['createdPlaylists'] ?? false,
        importSavedAlbums: _selectedItems['savedAlbums'] ?? false,
        importSavedPlaylists: _selectedItems['savedPlaylists'] ?? false,
        importfavoriteArtists: _selectedItems['favoriteArtists'] ?? false,
        importfavoriteSongs: _selectedItems['favoriteSongs'] ?? false,
        importAppSettings: _selectedItems['appSettings'] ?? false,
        importPlaybackHistory: _selectedItems['playbackHistory'] ?? false,

        importPlaylistSongs: _selectedItems['playlistSongs'] ?? false,
        importQueue: _selectedItems['queue'] ?? false,
        importPlaybackStats: _selectedItems['playbackStats'] ?? false,
        importRecentPlaylists: _selectedItems['recentPlaylists'] ?? false,
      );

      if (_selectedItems['favoriteSongs'] == true) {
        Provider.of<FavoriteSongProvider>(
          context,
          listen: false,
        ).loadLikedSongs(notify: true);
      }
      if (_selectedItems['favoriteArtists'] == true) {
        Provider.of<FavoriteArtistProvider>(
          context,
          listen: false,
        ).loadFavoriteArtists(notify: true);
      }
      if (_selectedItems['createdPlaylists'] == true ||
          _selectedItems['savedAlbums'] == true ||
          _selectedItems['savedPlaylists'] == true ||
          _selectedItems['playlistSongs'] == true) {
        Provider.of<PlaylistAlbumLibraryProvider>(
          context,
          listen: false,
        ).loadAll(notify: true);
      }

      if (_selectedItems['queue'] == true) {
        Provider.of<QueueProvider>(context, listen: false).loadQueue();
      }

      if (_selectedItems['appSettings'] == true) {
        Provider.of<SettingsProvider>(context, listen: false).loadSettings();
      }

      Navigator.pop(context);
      AppSnackBar.showSuccess(
        context,
        'data_imported_successfully_snackbar'.tr(),
      );
    } catch (e) {
      print('Error during import: $e');
      AppSnackBar.showError(context, 'import_failed_snackbar'.tr());
    }
  }
}
