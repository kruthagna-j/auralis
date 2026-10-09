import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class StreamProvider {
  final bool playable;
  final List<Audio>? audioFormats;
  final String statusMSG;
  StreamProvider({required this.playable, this.audioFormats, this.statusMSG = ""});

  static Future<StreamProvider> fetch(String videoId) async {
    final yt = YoutubeExplode();
    try {
      debugPrint('StreamProvider.fetch: fetching manifest for $videoId');
      // Use the standard Android client only. Android VR/iOS/Safari can return
      // GVS/SABR-protected streams that are not directly playable by mpv.
      final res = await yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [YoutubeApiClient.android],
        requireWatchPage: true,
      );
      final audio = res.audioOnly;
      debugPrint('StreamProvider.fetch: audioOnly count=${audio.length}, total audio=${res.audio.length}');
      final formats = <Audio>[];
      for (final e in audio) {
        formats.add(Audio(
          itag: e.tag,
          audioCodec: e.audioCodec.contains('mp') ? Codec.mp4a : Codec.opus,
          bitrate: e.bitrate.bitsPerSecond,
          duration: 0,
          loudnessDb: 0.0,
          url: e.url.toString(),
          size: e.size.totalBytes,
        ));
      }
      return StreamProvider(
        playable: formats.isNotEmpty,
        statusMSG: formats.isNotEmpty ? "OK" : "No audio stream available",
        audioFormats: formats,
      );
    } catch (e, st) {
      debugPrint('StreamProvider.fetch: exception: $e\n$st');
      if (e is SocketException) return StreamProvider(playable: false, statusMSG: "networkError: $e");
      if (e is VideoUnplayableException) return StreamProvider(playable: false, statusMSG: "Song is unplayable");
      if (e is VideoRequiresPurchaseException) return StreamProvider(playable: false, statusMSG: "Song requires purchase");
      if (e is VideoUnavailableException) return StreamProvider(playable: false, statusMSG: "Song is unavailable");
      if (e is YoutubeExplodeException) return StreamProvider(playable: false, statusMSG: e.message);
      return StreamProvider(playable: false, statusMSG: e.toString());
    } finally {
      yt.close();
    }
  }

  List<Audio> get _sorted => [...(audioFormats ?? const <Audio>[])]..sort((a, b) => a.bitrate.compareTo(b.bitrate));

  Audio? get highestQualityAudio {
    final sorted = _sorted;
    if (sorted.isEmpty) return null;
    final mp4a = sorted.where((item) => item.audioCodec == Codec.mp4a).toList();
    return mp4a.isNotEmpty ? mp4a.last : sorted.last;
  }

  Audio? get highestBitrateMp4aAudio {
    final sorted = _sorted.where((item) => item.audioCodec == Codec.mp4a).toList();
    return sorted.isNotEmpty ? sorted.last : null;
  }

  Audio? get highestBitrateOpusAudio {
    final sorted = _sorted.where((item) => item.audioCodec == Codec.opus).toList();
    return sorted.isNotEmpty ? sorted.last : null;
  }

  Audio? get lowQualityAudio {
    final sorted = _sorted;
    if (sorted.isEmpty) return null;
    final mp4a = sorted.where((item) => item.audioCodec == Codec.mp4a).toList();
    return mp4a.isNotEmpty ? mp4a.first : sorted.first;
  }
}

class Audio {
  final int itag;
  final Codec audioCodec;
  final int bitrate;
  final int duration;
  final int size;
  final double loudnessDb;
  final String url;
  Audio({required this.itag, required this.audioCodec, required this.bitrate, required this.duration, required this.loudnessDb, required this.url, required this.size});

  Map<String, dynamic> toJson() => {
    "itag": itag,
    "audioCodec": audioCodec.toString(),
    "bitrate": bitrate,
    "loudnessDb": loudnessDb,
    "url": url,
    "approxDurationMs": duration,
    "size": size,
  };

  factory Audio.fromJson(json) => Audio(
    audioCodec: (json["audioCodec"] as String).contains("mp4a") ? Codec.mp4a : Codec.opus,
    itag: json['itag'],
    duration: json["approxDurationMs"] ?? 0,
    bitrate: json["bitrate"] ?? 0,
    loudnessDb: (json['loudnessDb'])?.toDouble() ?? 0.0,
    url: json['url'],
    size: json["size"] ?? 0,
  );
}

enum Codec { mp4a, opus }
