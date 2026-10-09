import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/providers/queued_provider.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;
import '../models/song_model.dart';
import '../providers/player_provider.dart';

class IntentService {
  final PlayerProvider _playerProvider;
  final QueueProvider _queueProvider;
  StreamSubscription? _intentDataStreamSubscription;

  IntentService(this._playerProvider, this._queueProvider);

  Future<void> init() async {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (value) {
            if (value.isNotEmpty) {
              final sharedFile = value.first;
              if (sharedFile.path.endsWith('.mp3') ||
                  sharedFile.path.endsWith('.m4a') ||
                  sharedFile.path.endsWith('.wav') ||
                  sharedFile.path.endsWith('.flac')) {
                _handleAudioFile(sharedFile.path);
              }
            }
          },
          onError: (err) {
            debugPrint("getMediaStream error: $err");
          },
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        final sharedFile = value.first;
        if (sharedFile.path.endsWith('.mp3') ||
            sharedFile.path.endsWith('.m4a') ||
            sharedFile.path.endsWith('.wav') ||
            sharedFile.path.endsWith('.flac')) {
          _handleAudioFile(sharedFile.path);
        }
        ReceiveSharingIntent.instance.reset();
      }
    });

    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (value) {
            if (value.isNotEmpty) {
              final sharedFile = value.first;
              if (sharedFile.type == SharedMediaType.text) {
                _handleYoutubeUrl(sharedFile.path);
              }
            }
          },
          onError: (err) {
            debugPrint("getMediaStream error: $err");
          },
        );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        final sharedFile = value.first;
        if (sharedFile.type == SharedMediaType.text) {
          _handleYoutubeUrl(sharedFile.path);
        }
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  Future<void> _handleAudioFile(String path) async {
    Map<String, dynamic> songData;
    try {
      final metadata = await MetadataGod.readMetadata(file: path);
      Uint8List? artwork;
      final picData = metadata.picture?.data;
      if (picData != null) {
        if (picData is Uint8List) {
          artwork = picData;
        } else {
          artwork = Uint8List.fromList(List<int>.from(picData));
        }
      }

      String? thumbnailUri;
      if (artwork != null) {
        try {
          final tempDir = await getTemporaryDirectory();
          final hash = path.hashCode.toRadixString(16);
          final artFile = File('${tempDir.path}/artwork_$hash.jpg');
          if (!await artFile.exists()) {
            await artFile.writeAsBytes(artwork);
          }
          thumbnailUri = artFile.path;
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to write artwork file: $e');
        }
      }

      final rawDuration =
          metadata.durationMs ??
          (metadata.duration != null
              ? metadata.duration!.inMilliseconds
              : null);
      int? durationMsInt;
      if (rawDuration is double) {
        durationMsInt = rawDuration.toInt();
      } else if (rawDuration is int) {
        durationMsInt = rawDuration;
      } else if (rawDuration is String) {
        final rawStr = rawDuration as String;
        durationMsInt = int.tryParse(rawStr);
      } else {
        durationMsInt = null;
      }

      songData = {
        'id': path,
        'title': metadata.title ?? 'Unknown Title',
        'artist': metadata.artist ?? 'Unknown Artist',
        'album': metadata.album ?? 'Unknown Album',
        'duration': durationMsInt,
        'thumbnail': thumbnailUri,
        'localPath': path,
        'isLocal': true,
      };
    } on Exception catch (e) {
      if (kDebugMode) {
        debugPrint('Metadata read error for $path: $e');
      }
      songData = {
        'id': path,
        'title': path.split('/').last,
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': null,
        'thumbnail': null,
        'localPath': path,
        'isLocal': true,
      };
    } catch (e) {
      debugPrint('Error reading metadata for $path: $e');
      songData = {
        'id': path,
        'title': path.split('/').last,
        'artist': 'Unknown Artist',
        'album': 'Unknown Album',
        'duration': null,
        'thumbnail': null,
        'localPath': path,
        'isLocal': true,
      };
    }
    final songQueue = [songData];
    const currentIndex = 0;

    try {
      await _playerProvider.playerService.playLocalAudioWithQueue(
        path,
        songData,
        songQueue,
        currentIndex,
      );
    } catch (e) {
      debugPrint('Failed to play local song from intent: $e');
    }
  }

  Future<void> _handleYoutubeUrl(String url) async {
    final videoId = VideoId.parseVideoId(url);
    if (videoId != null) {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(videoId);

      final cleanedAuthor = video.author.endsWith(' - Topic')
          ? video.author.substring(0, video.author.length - ' - Topic'.length)
          : video.author;
      final song = SongInfo(
        videoId: video.id.value,
        name: video.title,
        artists: [Artist(name: cleanedAuthor, id: video.channelId.value)],
        thumbnails: [
          Thumbnail(url: video.thumbnails.highResUrl, width: 720, height: 1280),
        ],
        duration: video.duration ?? Duration.zero,
      );
      _queueProvider.clearQueue();
      _playerProvider.setCurrentSong(song);
      _playerProvider.playerService.playSong(song);
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
