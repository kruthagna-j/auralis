import 'dart:async';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song_model.dart';
import '../providers/settings_provider.dart';

class TempAudioCacheService {
  static const String _cacheDirName = 'auralis_stream_cache_v2';
  static const Duration _defaultMaxAge = Duration(days: 2);

  Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheDirName');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  String _buildSafeFileName(SongInfo song, String quality, String provider) {
    final sanitizedId = Uri.encodeComponent(song.videoId);
    final sanitizedQuality = Uri.encodeComponent(quality);
    final sanitizedProvider = Uri.encodeComponent(provider);
    return '$sanitizedId-$sanitizedQuality-$sanitizedProvider.m4a';
  }

  Future<String> _getProviderName() async {
    try {
      final settingsProvider = GetIt.I<SettingsProvider>();
      return settingsProvider.jioSaavnEnabled ? 'jiosaavn' : 'youtube';
    } catch (_) {
      return 'youtube';
    }
  }

  Future<File?> getCachedFile(SongInfo song) async {
    try {
      final settingsProvider = GetIt.I<SettingsProvider>();
      final provider = await _getProviderName();
      final fileName = _buildSafeFileName(
        song,
        settingsProvider.streamingQuality,
        provider,
      );
      final cacheDir = await _getCacheDirectory();
      final file = File('${cacheDir.path}/$fileName');
      if (!await file.exists()) {
        return null;
      }
      final length = await file.length();
      if (length < 64 * 1024 || !await _looksLikeIsoBaseMedia(file)) {
        try {
          await file.delete();
        } catch (_) {}
        return null;
      }
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<File> downloadAndCacheFile(String url, SongInfo song) async {
    final settingsProvider = GetIt.I<SettingsProvider>();
    final provider = await _getProviderName();
    final fileName = _buildSafeFileName(
      song,
      settingsProvider.streamingQuality,
      provider,
    );
    final cacheDir = await _getCacheDirectory();
    final file = File('${cacheDir.path}/$fileName');
    final tempFile = File('${file.path}.tmp');

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..idleTimeout = const Duration(seconds: 12);
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 Chrome/140.0.0.0 Mobile Safari/537.36',
      );
      request.headers.set(HttpHeaders.refererHeader, 'https://www.youtube.com/');
      request.headers.set(HttpHeaders.acceptHeader, '*/*');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Failed to download audio cache: ${response.statusCode}',
          uri: uri,
        );
      }
      final output = tempFile.openWrite(mode: FileMode.write);
      await response.pipe(output).timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException(
          'YouTube audio download timed out',
        ),
      );
      await output.close();
      final length = await tempFile.length();
      if (length < 64 * 1024 || !await _looksLikeIsoBaseMedia(tempFile)) {
        try {
          await tempFile.delete();
        } catch (_) {}
        throw const FormatException(
          'YouTube returned an invalid/non-M4A audio response',
        );
      }
      if (await file.exists()) {
        await file.delete();
      }
      return tempFile.renameSync(file.path);
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _looksLikeIsoBaseMedia(File file) async {
    try {
      final bytes = await file.openRead(0, 32).fold<List<int>>(
        <int>[],
        (all, chunk) => all..addAll(chunk),
      );
      if (bytes.length < 12) return false;
      final boxType = String.fromCharCodes(bytes.sublist(4, 8));
      return boxType == 'ftyp' ||
          boxType == 'styp' ||
          boxType == 'free' ||
          boxType == 'wide';
    } catch (_) {
      return false;
    }
  }

  Future<void> cleanupExpiredCache({Duration maxAge = _defaultMaxAge}) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final now = DateTime.now();
      await for (final entry in cacheDir.list()) {
        if (entry is File) {
          try {
            final stat = await entry.stat();
            if (now.difference(stat.modified) > maxAge) {
              await entry.delete();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      await for (final entry in cacheDir.list()) {
        if (entry is File) {
          try {
            await entry.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
