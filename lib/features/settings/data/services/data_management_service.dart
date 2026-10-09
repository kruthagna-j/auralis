import 'dart:convert';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/settings_storage_service.dart';
import '../../../../core/services/temp_audio_cache_service.dart';

class DataUsageStats {
  final int itemCount;
  final int sizeBytes;

  const DataUsageStats({required this.itemCount, required this.sizeBytes});

  static const empty = DataUsageStats(itemCount: 0, sizeBytes: 0);

  bool get isEmpty => itemCount <= 0 && sizeBytes <= 0;

  DataUsageStats operator +(DataUsageStats other) {
    return DataUsageStats(
      itemCount: itemCount + other.itemCount,
      sizeBytes: sizeBytes + other.sizeBytes,
    );
  }
}

class DataManagementService {
  static const String _tempAudioCacheDirName = 'auralis_stream_cache';

  Future<void> clearCache() async {
    final cacheDir = await getTemporaryDirectory();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  Future<void> clearTempAudioCache() async {
    await TempAudioCacheService().clearCache();
  }

  Future<void> _clearBox(String boxName) async {
    if (await Hive.boxExists(boxName)) {
      final box = await Hive.openBox<String>(boxName);
      await box.clear();
    }
  }

  Future<void> clearCreatedPlaylists() async =>
      await _clearBox('created_playlists');
  Future<void> clearSavedAlbums() async => await _clearBox('saved_albums');
  Future<void> clearSavedPlaylists() async =>
      await _clearBox('saved_playlists');
  Future<void> clearFavoriteArtists() async =>
      await _clearBox('favorite_artists');
  Future<void> clearLikedSongs() async => await _clearBox('liked_songs');
  Future<void> clearLastPlayed() async => await _clearBox('last_played');
  Future<void> clearQueue() async => await _clearBox('queue_storage');
  Future<void> clearPlaybackStats() async {
    await _clearBox('playback_stats');
    await _clearBox('playback_stats_daily');
    await _clearBox('playback_stats_daily_artist');
  }

  Future<void> clearPlaylistSongs() async => await _clearBox('playlist_songs');
  Future<void> clearAudioUrlCache() async => await _clearBox('audio_url_cache');
  Future<void> clearVideoInfoCache() async =>
      await _clearBox('video_info_cache');

  Future<void> clearRecentplaylists() async =>
      await _clearBox('recent_playlists');

  Future<void> clearRecentPlaylists() async => await clearRecentplaylists();

  Future<void> _clearSharedPreference(String key) async {
    final settingsBox = await SettingsStorageService.getBox();
    await settingsBox.delete(key);
  }

  Future<void> clearSearchHistory() async =>
      await _clearSharedPreference('search_history');

  Future<void> clearAllHiveData() async {
    await clearCreatedPlaylists();
    await clearSavedAlbums();
    await clearSavedPlaylists();
    await clearFavoriteArtists();
    await clearLikedSongs();
    await clearLastPlayed();
    await clearPlaylistSongs();
    await clearRecentplaylists();
    await clearQueue();
    await clearPlaybackStats();
    await clearAudioUrlCache();
    await clearVideoInfoCache();
  }

  Future<void> clearAllAppData() async {
    await clearAllHiveData();
    final settingsBox = await SettingsStorageService.getBox();
    await settingsBox.clear();

    await clearCache();

    final appDir = await getApplicationSupportDirectory();
    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }
  }

  Future<Map<String, DataUsageStats>> getClearActionStats() async {
    final Map<String, Future<DataUsageStats>> futures = {
      'clear_created_playlists': _getBoxStats('created_playlists'),
      'clear_saved_albums': _getBoxStats('saved_albums'),
      'clear_saved_playlists': _getBoxStats('saved_playlists'),
      'clear_favorite_artists': _getBoxStats('favorite_artists'),
      'clear_liked_songs': _getBoxStats('liked_songs'),
      'clear_playback_history': _getBoxStats('last_played'),
      'clear_search_history': _getSearchHistoryStats(),
      'clear_audio_url_cache': _getBoxStats('audio_url_cache'),
      'clear_temp_audio_cache': _getTempAudioCacheStats(),
      'clear_playlist_songs': _getBoxStats('playlist_songs'),
      'clear_video_info_cache': _getBoxStats('video_info_cache'),
      'clear_queue': _getBoxStats('queue_storage'),
      'clear_recent_playlists': _getBoxStats('recent_playlists'),
      'clear_playback_stats': _combineStats([
        await _getBoxStats('playback_stats'),
        await _getBoxStats('playback_stats_daily'),
        await _getBoxStats('playback_stats_daily_artist'),
      ]),
      'clear_cache': Future(() async {
        try {
          return await _getDirectoryStats(await getTemporaryDirectory());
        } catch (e) {
          return DataUsageStats.empty;
        }
      }),
      'app_support': Future(() async {
        try {
          return await _getDirectoryStats(
            await getApplicationSupportDirectory(),
          );
        } catch (e) {
          return DataUsageStats.empty;
        }
      }),
    };

    final Map<String, DataUsageStats> results = {};
    for (final entry in futures.entries) {
      try {
        results[entry.key] = await entry.value;
      } catch (e) {
        results[entry.key] = DataUsageStats.empty;
      }
    }

    results['clear_all_app_data'] = await _combineStats(
      results.values.toList(),
    );

    return results;
  }

  Future<DataUsageStats> _combineStats(List<DataUsageStats> statsList) async {
    return statsList.fold<DataUsageStats>(
      DataUsageStats.empty,
      (acc, current) => acc + current,
    );
  }

  Future<DataUsageStats> _getTempAudioCacheStats() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_tempAudioCacheDirName');
      return _getDirectoryStats(cacheDir);
    } catch (e) {
      return DataUsageStats.empty;
    }
  }

  Future<DataUsageStats> _getSearchHistoryStats() async {
    try {
      final settingsBox = await SettingsStorageService.getBox();
      if (!settingsBox.containsKey('search_history')) {
        return DataUsageStats.empty;
      }

      final value = settingsBox.get('search_history');
      return DataUsageStats(
        itemCount: _countItems(value),
        sizeBytes: _estimateValueSizeBytes(value),
      );
    } catch (e) {
      return DataUsageStats.empty;
    }
  }

  Future<DataUsageStats> _getBoxStats(String boxName) async {
    try {
      if (!await Hive.boxExists(boxName)) {
        return DataUsageStats.empty;
      }

      final box = await Hive.openBox<String>(boxName);
      var estimatedBytes = 0;
      for (final value in box.values) {
        estimatedBytes += _estimateValueSizeBytes(value);
      }

      return DataUsageStats(itemCount: box.length, sizeBytes: estimatedBytes);
    } catch (e) {
      return DataUsageStats.empty;
    }
  }

  Future<DataUsageStats> _getDirectoryStats(Directory dir) async {
    try {
      if (!await dir.exists()) {
        return DataUsageStats.empty;
      }

      var fileCount = 0;
      var totalBytes = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }
        fileCount++;
        try {
          totalBytes += await entity.length();
        } catch (_) {}
      }

      return DataUsageStats(itemCount: fileCount, sizeBytes: totalBytes);
    } catch (e) {
      return DataUsageStats.empty;
    }
  }

  int _estimateValueSizeBytes(dynamic value) {
    if (value == null) {
      return 0;
    }
    try {
      return utf8.encode(jsonEncode(value)).length;
    } catch (_) {
      return utf8.encode(value.toString()).length;
    }
  }

  int _countItems(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is Map) {
      return value.length;
    }
    if (value is Iterable) {
      return value.length;
    }
    return 1;
  }
}
