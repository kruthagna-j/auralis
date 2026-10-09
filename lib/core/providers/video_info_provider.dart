import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../utils/serializable_video.dart';

class CachedVideoInfo {
  final String videoId;
  final String title;
  final String author;
  final String channelId;
  final Duration? duration;
  final String thumbnailUrl;
  final int viewCount;
  final int? likeCount;
  final DateTime? publishDate;

  CachedVideoInfo({
    required this.videoId,
    required this.title,
    required this.author,
    required this.channelId,
    this.duration,
    required this.thumbnailUrl,
    required this.viewCount,
    this.likeCount,
    this.publishDate,
  });

  factory CachedVideoInfo.fromVideo(Video video) {
    return CachedVideoInfo(
      videoId: video.id.value,
      title: video.title,
      author: video.author,
      channelId: video.channelId.value,
      duration: video.duration,
      thumbnailUrl: video.thumbnails.highResUrl,
      viewCount: video.engagement.viewCount,
      likeCount: video.engagement.likeCount,
      publishDate: video.publishDate,
    );
  }
}

class VideoInfoProvider extends ChangeNotifier {
  final _yt = GetIt.I<YoutubeExplode>();
  final Box<String> _cacheBox = Hive.box('video_info_cache');
  final Map<String, Future<CachedVideoInfo?>> _fetchFutures = {};

  Future<CachedVideoInfo?> getVideoInfo(
    String videoId, {
    int expiryDays = 30,
  }) async {
    if (_fetchFutures.containsKey(videoId)) {
      return _fetchFutures[videoId];
    }

    final completer = Completer<CachedVideoInfo?>();
    _fetchFutures[videoId] = completer.future;

    try {
      final rawCachedData = _cacheBox.get('raw_video_$videoId');
      if (rawCachedData != null) {
        final decodedData = json.decode(rawCachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(decodedData['timestamp']);

        if (DateTime.now().difference(timestamp).inDays < expiryDays) {
          debugPrint(
            'Fetching video details from raw video cache for $videoId',
          );
          final serializableVideo = SerializableVideo.fromJson(
            decodedData['video'],
          );
          final info = CachedVideoInfo.fromVideo(serializableVideo.toVideo());
          completer.complete(info);
          _fetchFutures.remove(videoId);
          return info;
        }
      }

      final cachedData = _cacheBox.get(videoId);
      if (cachedData != null) {
        final decodedData = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(decodedData['timestamp']);

        if (DateTime.now().difference(timestamp).inDays < expiryDays) {
          debugPrint('Fetching video details from slim cache for $videoId');
          final info = _infoFromCache(videoId, decodedData);
          completer.complete(info);
          _fetchFutures.remove(videoId);
          return info;
        }
      }

      debugPrint('Fetching video details from network for $videoId');
      final video = await _yt.videos.get(VideoId(videoId));
      final info = CachedVideoInfo.fromVideo(video);
      _cacheVideo(info);
      _cacheRawVideo(video);
      completer.complete(info);
      return info;
    } catch (e) {
      debugPrint('Error fetching video details for $videoId: $e');
      completer.complete(null);
      return null;
    } finally {
      _fetchFutures.remove(videoId);
    }
  }

  Future<Video?> getRawVideo(String videoId, {int expiryDays = 30}) async {
    try {
      final cachedData = _cacheBox.get('raw_video_$videoId');
      if (cachedData != null) {
        final decodedData = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(decodedData['timestamp']);

        if (DateTime.now().difference(timestamp).inDays < expiryDays) {
          debugPrint('Fetching raw video from cache for $videoId');
          final serializableVideo = SerializableVideo.fromJson(
            decodedData['video'],
          );
          return serializableVideo.toVideo();
        }
      }

      debugPrint('Fetching raw video from network for $videoId');
      final video = await _yt.videos.get(VideoId(videoId));
      _cacheRawVideo(video);
      return video;
    } catch (e) {
      debugPrint('Error fetching raw video for $videoId: $e');
      return null;
    }
  }

  void _cacheVideo(CachedVideoInfo info) {
    final dataToCache = {
      'title': info.title,
      'author': info.author,
      'channelId': info.channelId,
      'duration': info.duration?.inSeconds,
      'thumbnailUrl': info.thumbnailUrl,
      'viewCount': info.viewCount,
      'likeCount': info.likeCount,
      'publishDate': info.publishDate?.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    _cacheBox.put(info.videoId, json.encode(dataToCache));
  }

  void _cacheRawVideo(Video video) {
    final serializableVideo = SerializableVideo.fromVideo(video);
    final dataToCache = {
      'video': serializableVideo.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    _cacheBox.put('raw_video_${video.id.value}', json.encode(dataToCache));
  }

  CachedVideoInfo _infoFromCache(
    String videoId,
    Map<String, dynamic> cachedData,
  ) {
    return CachedVideoInfo(
      videoId: videoId,
      title: cachedData['title'] ?? '',
      author: cachedData['author'] ?? '',
      channelId: cachedData['channelId'] ?? '',
      duration: cachedData['duration'] != null
          ? Duration(seconds: cachedData['duration'])
          : null,
      thumbnailUrl: cachedData['thumbnailUrl'] ?? '',
      viewCount: cachedData['viewCount'] ?? 0,
      likeCount: cachedData['likeCount'],
      publishDate: cachedData['publishDate'] != null
          ? DateTime.parse(cachedData['publishDate'])
          : null,
    );
  }
}
