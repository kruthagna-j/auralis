import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/models/song_model.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/duration_utils.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    hide Thumbnail, Playlist;

import '../providers/video_info_provider.dart';
import 'yt-music-api.dart';

class ContentDetailsService {
  final YTMusic _ytMusic = GetIt.I<YTMusic>();
  final _yt = GetIt.I<YoutubeExplode>();
  static const int _initialArtistAlbumLimit = 100;

  static Future<SongInfo> resolveSongInfoDuration(SongInfo songInfo) async {
    if (songInfo.duration.inSeconds > 0) return songInfo;

    try {
      final videoInfoProvider = GetIt.I<VideoInfoProvider>();
      final videoInfo = await videoInfoProvider.getVideoInfo(songInfo.videoId);
      if (videoInfo?.duration != null) {
        return SongInfo(
          videoId: songInfo.videoId,
          name: songInfo.name,
          artists: songInfo.artists,
          thumbnails: songInfo.thumbnails,
          duration: videoInfo!.duration!,
        );
      }
    } catch (e) {
      debugPrint('Error resolving song duration: $e');
    }
    return songInfo;
  }

  static const int _initialPlaylistAlbumSongLimit = 200;
  static const int _initialArtistPopularSongLimit = 200;
  static const int _initialArtistSinglesSongLimit = 200;

  Future<Map<String, dynamic>> getArtistDetailsAndSimilar(
    String artistId,
  ) async {
    final artist = await _ytMusic.getArtist(artistId);
    final artistDetailed = ArtistDetailed(
      artistId: artist.artistId,
      name: artist.name,
      thumbnails: artist.thumbnails,
      type: artist.type,
    );
    return {
      'artistInfo': artistDetailed,
      'similarArtists': artist.similarArtists
          .map(
            (similarArtist) => ArtistInfo(
              id: similarArtist.artistId,
              name: similarArtist.name,
              thumbnailUrl: similarArtist.thumbnails.last.url.replaceAll(
                'w60-h60',
                'w600-h600',
              ),
            ),
          )
          .toList(),
    };
  }

  Future<Map<String, dynamic>> loadContentSongs(dynamic content) async {
    try {
      debugPrint('Content Type: ${content.runtimeType}');
      debugPrint('Content Properties: ${content.toString()}');
      String? id;

      if (content is AlbumDetailed) {
        id = content.playlistId;
      } else if (content is PlaylistDetailed) {
        id = content.playlistId;
      }

      if (id == null) {
        throw Exception('Unable to extract ID from content');
      }

      Map<String, dynamic> result;
      if (content is AlbumDetailed) {
        result = await getPlaylistAlbumSongs(albumId: id);
      } else {
        result = await getPlaylistAlbumSongs(playlistId: id);
      }

      final playlistInfo = result['playlist'];
      final songsData = result['songs'] as List<dynamic>;

      final transformedSongs = songsData.map((song) {
        final artists =
            (song['artists'] as List<dynamic>?)
                ?.map((a) => Artist(name: a['name'] ?? '', id: a['id'] ?? ''))
                .toList() ??
            [];

        final thumbnails =
            (song['thumbnails'] as List<dynamic>?)
                ?.map(
                  (t) => Thumbnail(
                    url: t['url'] ?? '',
                    width: t['width'] ?? 0,
                    height: t['height'] ?? 0,
                  ),
                )
                .toList() ??
            [];

        final durationString = song['length'] as String?;
        final duration = DurationUtils.parseDuration(durationString);

        return SongInfo(
          videoId: song['videoId'] ?? '',
          name: song['title'] ?? '',
          artists: artists,
          thumbnails: thumbnails,
          duration: duration,
        );
      }).toList();

      final description = content is AlbumDetailed
          ? '${playlistInfo['title'] ?? 'Unknown Artist'} • Album • ${transformedSongs.length} songs'
          : 'Playlist • ${transformedSongs.length} songs';

      return {
        'allSongs': transformedSongs,
        'songs': transformedSongs.take(_initialPlaylistAlbumSongLimit).toList(),
        'description': description,
      };
    } catch (e) {
      throw Exception('Error loading content service: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> loadArtistSongs(String artistId) async {
    final allSongs = await _ytMusic.getArtistSongs(artistId);
    return {
      'allSongs': allSongs,
      'songs': allSongs.take(_initialArtistPopularSongLimit).toList(),
    };
  }

  Future<Map<String, dynamic>> loadArtistAlbums(String artistId) async {
    final allAlbums = await _ytMusic.getArtistAlbums(artistId);
    return {
      'allAlbums': allAlbums,
      'albums': allAlbums.take(_initialArtistAlbumLimit).toList(),
    };
  }

  Future<Map<String, dynamic>> loadArtistSingles(String artistId) async {
    final allSingles = await _ytMusic.getArtistSingles(artistId);
    return {
      'allSingles': allSingles,
      'singles': allSingles.take(_initialArtistSinglesSongLimit).toList(),
    };
  }

  Future<List<dynamic>> loadMoreContent(
    List<dynamic> currentContent,
    List<dynamic> allContent,
    int currentPage,
    int limit,
  ) {
    final start = currentPage * limit;
    final newContent = [...currentContent];
    newContent.addAll(allContent.skip(start).take(limit));
    return Future.value(newContent);
  }

  String? extractPlaylistId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]list=)|youtu\.be\/)([^"&?\/\s]{11,})[^"&?\/\s]*',
    );
    RegExp regExpMusic = RegExp(
      r'music\.youtube\.com\/playlist\?list=([a-zA-Z0-9_-]+)',
    );

    Match? match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    match = regExpMusic.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  Future<Map<String, dynamic>?> getPlaylistDetails(String playlistId) async {
    try {
      final playlist = await _yt.playlists.get(playlistId);
      final allSongs = await _yt.playlists.getVideos(playlist.id).toList();

      final totalSeconds = allSongs.fold(
        0,
        (sum, song) => sum + (song.duration?.inSeconds ?? 0),
      );

      final String rawTitle = playlist.title;
      String contentType = 'Playlist';
      String name = rawTitle;
      String artist = playlist.author;

      if (rawTitle.toLowerCase().startsWith('album - ')) {
        contentType = 'Album';
        name = rawTitle
            .replaceFirst(RegExp(r'^album\s*-\s*', caseSensitive: false), '')
            .trim();

        if (allSongs.isNotEmpty) {
          artist = allSongs.first.author.endsWith(' - Topic')
              ? allSongs.first.author.substring(
                  0,
                  allSongs.first.author.length - ' - Topic'.length,
                )
              : allSongs.first.author;
        }
      }

      String thumbnailUrl = playlist.thumbnails.highResUrl;
      if (allSongs.isNotEmpty) {
        thumbnailUrl = allSongs.first.thumbnails.highResUrl;
      }

      return {
        'name': name,
        'thumbnail': thumbnailUrl,
        'duration': totalSeconds,
        'playlistId': playlist.id.value,
        'contentType': contentType,
        'artist': artist,
      };
    } catch (e) {
      debugPrint('Error getting playlist details: $e');
      return null;
    }
  }

  Future<void> playSong(
    dynamic song,
    dynamic playerProvider,
    dynamic queueProvider,
    List<dynamic> songs, {
    String? playlistId,
    String? playlistName,
    String? playlistThumbnail,
    bool? isPlaylist,
  }) async {
    try {
      final songIndex = songs.indexWhere((s) => s.videoId == song.videoId);

      if (playlistId != null && queueProvider.playlistId == playlistId) {
        if (playlistName != null &&
            playlistName.isNotEmpty &&
            queueProvider.playlistName != playlistName) {
          queueProvider.setPlaylistName(playlistName);
        }

        if (songIndex != -1) {
          await playerProvider.playerService.playSong(song);
        } else {
          queueProvider.setQueue(
            songs.cast<SongInfo>(),
            currentIndex: songIndex,
            playlistId: playlistId,
            playlistName: playlistName,
          );
          await playerProvider.playerService.playSong(song);
        }
      } else {
        queueProvider.setQueue(
          songs.cast<SongInfo>(),
          currentIndex: songIndex,
          playlistId: playlistId,
          playlistName: playlistName,
        );
        if (playlistId != null &&
            playlistName != null &&
            playlistThumbnail != null) {
          playerProvider.addRecentPlaylist(
            playlistId,
            playlistName,
            playlistThumbnail,
            isPlaylist: isPlaylist ?? true,
          );
        }

        await playerProvider.playerService.playSong(song);
      }
    } catch (e) {
      throw Exception('Error playing song: ${e.toString()}');
    }
  }
}
