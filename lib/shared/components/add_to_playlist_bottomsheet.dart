import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/playlists/data/providers/playlist_album_library_provider.dart';
import 'app_snackbar.dart';

class AddToPlaylistBottomSheet extends StatefulWidget {
  final Map<String, dynamic> song;

  const AddToPlaylistBottomSheet({Key? key, required this.song})
    : super(key: key);

  @override
  _AddToPlaylistBottomSheetState createState() =>
      _AddToPlaylistBottomSheetState();
}

class _AddToPlaylistBottomSheetState extends State<AddToPlaylistBottomSheet> {
  List<Map<String, dynamic>> _playlists = [];
  Map<String, bool> _songInPlaylist = {};
  final TextEditingController _playlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadPlaylists();
    await _checkSongInPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    if (!provider.hasLoadedCreatedPlaylists) {
      await provider.loadCreatedPlaylists();
    }
    setState(() {
      _playlists = provider.createdPlaylists;
    });
  }

  Future<void> _checkSongInPlaylists() async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );

    final Map<String, bool> map = {};
    for (final playlist in _playlists) {
      final playlistName = playlist['name']?.toString() ?? '';
      if (playlistName.isEmpty) {
        continue;
      }
      final songs = await provider.getPlaylistSongs(playlistName);
      map[playlistName] = songs.any(
        (s) => s['id']?.toString() == widget.song['id']?.toString(),
      );
    }

    setState(() {
      _songInPlaylist = map;
    });
  }

  Future<void> _addToPlaylist(String playlistName) async {
    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;

    final alreadyIn = _songInPlaylist[playlistName] ?? false;

    if (alreadyIn) {
      await provider.removeSongFromPlaylist(
        playlistName,
        widget.song['id']?.toString() ?? '',
      );
      setState(() {
        _songInPlaylist[playlistName] = false;
      });

      AppSnackBar.showInfo(
        context,
        'removed_from_playlist'.tr(args: [playlistName]),
        accentColor: accentColor,
      );
    } else {
      await provider.saveSongToPlaylist(playlistName, widget.song);
      setState(() {
        _songInPlaylist[playlistName] = true;
      });

      AppSnackBar.showSuccess(
        context,
        'added_to_playlist'.tr(args: [playlistName]),
        accentColor: accentColor,
      );
    }
  }

  Future<void> _createNewPlaylist() async {
    final name = _playlistNameController.text.trim();
    if (name.isEmpty) return;

    final provider = Provider.of<PlaylistAlbumLibraryProvider>(
      context,
      listen: false,
    );

    try {
      await provider.saveCreatedPlaylist(name);
    } catch (e) {
      AppSnackBar.showError(
        context,
        'playlist_already_exists'.tr(args: [name]),
      );
      return;
    }

    await _loadPlaylists();

    setState(() {
      _songInPlaylist[name] = false;
    });

    await _addToPlaylist(name);

    _playlistNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: screenHeight * 0.5,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingXl,
          vertical: AppDimens.paddingLg,
        ),
        decoration: BoxDecoration(
          color: MainScreenColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimens.radiusXxxl),
            topRight: Radius.circular(AppDimens.radiusXxxl),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimens.dragHandleWidth,
              height: AppDimens.dragHandleHeight,
              margin: EdgeInsets.only(bottom: AppDimens.spacingXl),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: AppDimens.opacityOverlay),
                borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
              ),
            ),
            Text(
              'add_to_playlist'.tr(),
              style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
            ),
            SizedBox(height: AppDimens.spacingXxl),
            TextField(
              controller: _playlistNameController,
              cursorColor: accentColor,
              decoration: InputDecoration(
                hintText: 'new_playlist_name'.tr(),
                filled: true,
                fillColor: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: AppDimens.opacityLight),
                hintStyle: AppTextStyles.caption(isDarkMode: isDarkMode)
                    .copyWith(
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: AppDimens.opacitySemi),
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingXl,
                  vertical: AppDimens.paddingLg,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle_outline, color: accentColor),
                  onPressed: _createNewPlaylist,
                ),
              ),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
            ),
            SizedBox(height: AppDimens.spacingXl),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  final name = playlist['name']?.toString() ?? '';
                  return Card(
                    elevation: 0,
                    color: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: AppDimens.opacitySubtle),
                    margin: EdgeInsets.only(bottom: AppDimens.spacingSm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingXl,
                        vertical: AppDimens.paddingXs,
                      ),
                      title: Text(
                        name,
                        style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                      ),
                      trailing: _songInPlaylist[name] ?? false
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: AppDimens.spacingSm),
                                Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                              ],
                            )
                          : Icon(Icons.add_circle_outline, color: accentColor),
                      onTap: () => _addToPlaylist(name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
