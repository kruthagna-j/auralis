import 'package:get_it/get_it.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;

import '../models/song_model.dart';
import '../providers/video_info_provider.dart';

class RelatedSongService {
  final YoutubeExplode _yt = GetIt.I<YoutubeExplode>();
  final VideoInfoProvider _videoInfoProvider = GetIt.I<VideoInfoProvider>();

  static const Duration _maxDurationThreshold = Duration(minutes: 20);
  static const List<String> _movieKeywords = [
    'full movie',
    'complete movie',
    'hd movie',
    'trailer',
    'teaser',
    'official trailer',
    'full film',
    'entire movie',
    'movie clip',
    'film clip',
    'cinema',
    'bollywood movie',
    'hollywood movie',
    'full length',
    'complete film',
    'official movie',
    'movie scene',
    'film scene',
    'full hd movie',
    '4k movie',
    'episode',
    'tv show',
    'series',
    'season',
    'part 1',
    'part 2',
    'part 3',
  ];

  Future<List<SongInfo>> getRelatedSongs(String videoId) async {
    try {
      final video = await _videoInfoProvider.getRawVideo(videoId);
      if (video == null) {
        throw Exception('Failed to get raw video for $videoId');
      }

      final relatedVideos = await _yt.videos.getRelatedVideos(video);
      if (relatedVideos == null || relatedVideos.isEmpty) {
        return [];
      }

      final filteredVideos = _filterMovies(relatedVideos);
      final relatedSongs = filteredVideos
          .map((video) => _convertToSongInfo(video))
          .toList();

      return relatedSongs;
    } catch (e) {
      throw Exception('Failed to get related songs: $e');
    }
  }

  List<Video> _filterMovies(List<Video> videos) {
    return videos.where((video) {
      if (video.duration != null && video.duration! > _maxDurationThreshold) {
        return false;
      }

      final titleLower = video.title.toLowerCase();
      for (final keyword in _movieKeywords) {
        if (titleLower.contains(keyword)) {
          return false;
        }
      }

      final episodePattern = RegExp(
        r'\b(ep|episode)\s*\d+\b',
        caseSensitive: false,
      );
      if (episodePattern.hasMatch(titleLower)) {
        return false;
      }

      final yearPattern = RegExp(r'\b(19|20)\d{2}\b');
      if (yearPattern.hasMatch(titleLower) && titleLower.contains('movie')) {
        return false;
      }

      return true;
    }).toList();
  }

  SongInfo _convertToSongInfo(Video video) {
    return SongInfo(
      videoId: video.id.value,
      name: video.title,
      artists: [
        Artist(name: _cleanArtistName(video.author), id: video.channelId.value),
      ],
      thumbnails: [
        Thumbnail(url: video.thumbnails.highResUrl, width: 1280, height: 720),
      ],
      duration: video.duration ?? Duration.zero,
    );
  }

  String _cleanArtistName(String author) {
    if (author.endsWith(' - Topic')) {
      return author.substring(0, author.length - ' - Topic'.length);
    }
    return author;
  }

  Future<List<SongInfo>> createSongListWithRelated(
    SongInfo mainSong,
    String videoId,
  ) async {
    final relatedSongs = await getRelatedSongs(videoId);
    return [mainSong, ...relatedSongs];
  }
}
