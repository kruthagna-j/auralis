import 'package:dart_ytmusic_api/types.dart';
import '../../../../core/services/content_details_service.dart';
import 'package:get_it/get_it.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/video_info_provider.dart';
import '../../../../core/services/related_song_service.dart';

class HomeScreenQueueService {
  final BuildContext context;
  final YoutubeExplode _yt;
  final ContentDetailsService _contentDetailsService = ContentDetailsService();
  final RelatedSongService _relatedSongService = RelatedSongService();

  HomeScreenQueueService(this.context) : _yt = GetIt.I<YoutubeExplode>();

  Future<void> playAndQueueSongs(Map<String, dynamic> song) async {
    final ytPlayerProvider = Provider.of<PlayerProvider>(
      context,
      listen: false,
    );
    final ytQueueProvider = Provider.of<QueueProvider>(context, listen: false);
    final videoInfoProvider = Provider.of<VideoInfoProvider>(
      context,
      listen: false,
    );

    try {
      final videoId = song['id'] ?? song['videoId'];
      if (videoId == null) {
        throw Exception('Video ID not found');
      }

      final videoInfo = await videoInfoProvider.getVideoInfo(videoId);
      if (videoInfo == null) {
        throw Exception('Video details not found');
      }

      final cleanedAuthor = videoInfo.author.endsWith(' - Topic')
          ? videoInfo.author.substring(
              0,
              videoInfo.author.length - ' - Topic'.length,
            )
          : videoInfo.author;
      final songInfo = SongInfo(
        videoId: videoInfo.videoId,
        name: videoInfo.title,
        artists: [Artist(name: cleanedAuthor, id: videoInfo.channelId)],
        thumbnails: [
          Thumbnail(url: videoInfo.thumbnailUrl, width: 1280, height: 720),
        ],
        duration: videoInfo.duration ?? Duration.zero,
      );

      final all = await _relatedSongService.createSongListWithRelated(
        songInfo,
        videoId,
      );
      ytQueueProvider.setQueue(all, currentIndex: 0);
      ytPlayerProvider.playerService.playSong(songInfo);
    } catch (e) {
      throw Exception('Error playing and queuing songs: ${e.toString()}');
    }
  }

  Future<void> playArtistSongs(String artistId) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    try {
      final songsData = await _contentDetailsService.loadArtistSongs(artistId);
      final allSongs = songsData['allSongs'];

      if (allSongs.isEmpty) {
        throw Exception('No songs found for this artist.');
      }

      final List<SongInfo> convertedSongs = allSongs.map<SongInfo>((s) {
        if (s is SongDetailed) {
          return SongInfo(
            videoId: s.videoId,
            name: s.name,
            artists: [Artist(name: s.artist.name, id: s.artist.artistId ?? '')],
            thumbnails: s.thumbnails
                .map(
                  (t) =>
                      Thumbnail(url: t.url, width: t.width, height: t.height),
                )
                .toList(),
            duration: s.duration != null
                ? Duration(seconds: s.duration!)
                : Duration.zero,
          );
        } else if (s is SongInfo) {
          return s;
        } else {
          throw Exception('Invalid song type in list: ${s.runtimeType}');
        }
      }).toList();

      final playlistName =
          convertedSongs.isNotEmpty && convertedSongs.first.artists.isNotEmpty
          ? convertedSongs.first.artists.first.name
          : 'Unknown Artist';

      await _contentDetailsService.playSong(
        convertedSongs.first,
        playerProvider,
        queueProvider,
        convertedSongs,
        playlistId: artistId,
        playlistName: playlistName,
      );
      await queueProvider.saveQueue();
    } catch (e) {
      throw Exception('Error playing artist songs: ${e.toString()}');
    }
  }

  Future<void> playAll(String playlistType, {int currentIndex = 0}) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    try {
      List<Map<String, dynamic>> songsData = [];
      String playlistId = '';

      if (playlistType == 'recently_played') {
        songsData = playerProvider.lastPlayedSongs;
        playlistId = 'recently_played';
      } else if (playlistType == 'liked_songs') {
        final favoriteSongProvider = Provider.of<FavoriteSongProvider>(
          context,
          listen: false,
        );
        songsData = favoriteSongProvider.likedSongs;
        playlistId = 'liked_songs';
      }

      if (songsData.isEmpty) {
        throw Exception('No songs found in $playlistType.');
      }

      final List<SongInfo> convertedSongs = songsData.map<SongInfo>((song) {
        final artists = song['artists'] != null
            ? (song['artists'] as List)
                  .map((a) => Artist(name: a['name'], id: a['id']))
                  .toList()
            : [
                Artist(
                  name: song['artist'] ?? 'Unknown Artist',
                  id: song['artistId'] ?? '',
                ),
              ];
        return SongInfo(
          videoId: song['id'] ?? song['videoId'] ?? '',
          name: song['title'] ?? song['name'] ?? 'Unknown Title',
          artists: artists,
          thumbnails: [
            Thumbnail(
              url: song['thumbnail'] ?? 'assets/default_artwork.png',
              width: 1280,
              height: 720,
            ),
          ],
          duration: Duration(seconds: song['duration'] ?? 0),
        );
      }).toList();

      if (currentIndex < 0 || currentIndex >= convertedSongs.length) {
        currentIndex = 0;
      }

      final String playlistName = playlistType == 'recently_played'
          ? 'Recently'
          : (playlistType == 'liked_songs' ? 'favorites' : playlistId);

      await _contentDetailsService.playSong(
        convertedSongs[currentIndex],
        playerProvider,
        queueProvider,
        convertedSongs,
        playlistId: playlistId,
        playlistName: playlistName,
      );
      queueProvider.setQueue(
        convertedSongs,
        currentIndex: currentIndex,
        playlistId: playlistId,
        playlistName: playlistName,
      );
      await queueProvider.saveQueue();
    } catch (e) {
      throw Exception('Error playing $playlistType: ${e.toString()}');
    }
  }
}
