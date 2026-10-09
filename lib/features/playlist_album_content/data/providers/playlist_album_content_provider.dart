import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/content_details_service.dart';
import '../../../../core/models/song_model.dart';
import '../../../playlists/data/providers/playlist_album_library_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/download_provider.dart';

class PlaylistAlbumContentProvider extends ChangeNotifier {
  final ContentDetailsService _contentService = ContentDetailsService();
  final YTMusic _ytMusic = GetIt.I<YTMusic>();

  dynamic _content;
  bool _isLoading = true;
  String _contentDescription = '';
  List<dynamic> _songs = [];
  List<dynamic> _allSongs = [];
  int _currentSongPage = 0;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  bool _isSaved = false;

  bool get isLoading => _isLoading;
  String get contentDescription => _contentDescription;
  List<dynamic> get songs => _songs;
  List<dynamic> get allSongs => _allSongs;
  int get currentSongPage => _currentSongPage;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying => _isPlaying;
  bool get isSaved => _isSaved;

  Future<void> loadContent(dynamic content) async {
    _content = content;
    try {
      if (content is AlbumDetailed) {
        final album = await _ytMusic.getAlbum(content.albumId);
        final transformedSongs = album.songs.map((song) {
          return SongInfo(
            videoId: song.videoId,
            name: song.name,
            artists: [
              Artist(
                name: song.artist.name,
                id: song.artist.artistId ?? '',
              ),
            ],
            thumbnails: song.thumbnails
                .map(
                  (thumbnail) => Thumbnail(
                    url: thumbnail.url,
                    width: thumbnail.width,
                    height: thumbnail.height,
                  ),
                )
                .toList(),
            duration: Duration(seconds: song.duration ?? 0),
          );
        }).where((song) => song.videoId.isNotEmpty).toList();

        _songs = transformedSongs;
        _allSongs = transformedSongs;
        _contentDescription =
            '${content.name} • Album • ${transformedSongs.length} songs';
        _totalDuration = Duration(
          seconds: transformedSongs.fold(
            0,
            (sum, song) => sum + song.duration.inSeconds,
          ),
        );
      } else {
        final contentData = await _contentService.loadContentSongs(content);
        final totalSeconds = contentData['allSongs'].fold(
          0,
          (sum, song) => sum + song.duration.inSeconds,
        );
        _songs = contentData['songs'];
        _allSongs = contentData['allSongs'];
        _contentDescription = contentData['description'];
        _totalDuration = Duration(seconds: totalSeconds);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading content: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkIfSaved(
    dynamic content,
    PlaylistAlbumLibraryProvider libraryProvider,
  ) async {
    final contentType = content is AlbumDetailed ? 'Album' : 'Playlist';
    await libraryProvider.loadAll();
    final savedItems = contentType == 'Album'
        ? libraryProvider.savedAlbums
        : libraryProvider.savedPlaylists;
    _isSaved = savedItems.any(
      (item) => item['playlistId'] == content.playlistId,
    );
    notifyListeners();
  }

  Future<String> addToLibrary(
    dynamic content,
    String contentDescription,
    Duration totalDuration,
    PlaylistAlbumLibraryProvider libraryProvider,
  ) async {
    final contentType = contentDescription.contains('Playlist')
        ? 'Playlist'
        : 'Album';
    final contentData = {
      'name': content.name,
      'thumbnail': content.thumbnails.last.url,
      'duration': totalDuration.inSeconds,
      'playlistId': content.playlistId,
      'contentType': contentType,
      'artist': contentType == 'Album' ? content.artist.name : '',
    };
    if (contentType == 'Playlist') {
      await libraryProvider.savePlaylist(contentData);
    } else if (contentType == 'Album') {
      await libraryProvider.saveAlbum(contentData);
    }
    _isSaved = true;
    notifyListeners();
    return 'Added to library';
  }

  Future<String> removeFromLibrary(
    dynamic content,
    String contentDescription,
    PlaylistAlbumLibraryProvider libraryProvider,
  ) async {
    final contentType = contentDescription.contains('Playlist')
        ? 'Playlist'
        : 'Album';
    final playlistId = content.playlistId;
    if (contentType == 'Playlist') {
      await libraryProvider.deletePlaylist(playlistId);
    } else if (contentType == 'Album') {
      await libraryProvider.deleteAlbum(playlistId);
    }
    _isSaved = false;
    notifyListeners();
    return 'Removed from library';
  }

  Future<void> playSong(
    dynamic song,
    PlayerProvider playerProvider,
    QueueProvider queueProvider,
    List<dynamic> allSongs,
    String playlistId,
  ) async {
    try {
      final playlistName = _content?.name ?? '';
      final playlistThumbnail = _content?.thumbnails?.last?.url ?? '';
      await _contentService.playSong(
        song,
        playerProvider,
        queueProvider,
        allSongs,
        playlistId: playlistId,
        playlistName: playlistName,
        playlistThumbnail: playlistThumbnail,
        isPlaylist: _content is PlaylistDetailed,
      );
      await queueProvider.saveQueue();
    } catch (e) {
      throw e;
    }
  }

  Future<List<dynamic>> loadMoreSongs() async {
    final newSongs = await _contentService.loadMoreContent(
      _songs,
      _allSongs,
      _currentSongPage + 1,
      100,
    );
    _currentSongPage++;
    _songs = newSongs;
    notifyListeners();
    return newSongs;
  }

  String formatTotalDuration() {
    final hours = _totalDuration.inHours;
    final minutes = _totalDuration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hr ${minutes} min';
    }
    return '${minutes} min';
  }

  void shareContent(dynamic content, String contentDescription) {
    final contentType = contentDescription.toLowerCase().contains('playlist')
        ? 'playlist'
        : 'album';
    final shareText =
        'Check out this ${contentType}: ${content.name} : https://www.music.youtube.com/playlist?list=${content.playlistId}';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> downloadPlaylist(DownloadProvider downloadProvider) async {
    if (_allSongs.isEmpty) return;

    final playlistName = _content?.name ?? 'Unknown Playlist';
    await downloadProvider.downloadPlaylist(_allSongs, playlistName);
  }
}
