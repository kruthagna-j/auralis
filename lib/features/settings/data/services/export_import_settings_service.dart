import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/settings_storage_service.dart';

class ExportImportSettingsService {
  Future<Map<String, dynamic>> exportSelectedData({
    required bool exportCreatedPlaylists,
    required bool exportSavedAlbums,
    required bool exportSavedPlaylists,
    required bool exportfavoriteArtists,
    required bool exportfavoriteSongs,
    required bool exportAppSettings,
    required bool exportPlaybackHistory,
    required bool exportPlaylistSongs,
    required bool exportQueue,
    required bool exportPlaybackStats,
    required bool exportRecentPlaylists,
  }) async {
    final Map<String, dynamic> exportData = {};

    if (exportCreatedPlaylists) {
      exportData['createdPlaylists'] = await _exportCreatedPlaylistsData();
    }
    if (exportSavedAlbums) {
      exportData['savedAlbums'] = await _exportSavedAlbumsData();
    }
    if (exportSavedPlaylists) {
      exportData['savedPlaylists'] = await _exportSavedPlaylistsData();
    }
    if (exportfavoriteArtists) {
      exportData['favoriteArtists'] = await _exportfavoriteArtistsData();
    }
    if (exportfavoriteSongs) {
      exportData['favoriteSongs'] = await _exportfavoriteSongsData();
    }
    if (exportAppSettings) {
      exportData['appSettings'] = await _exportAppSettingsData();
    }
    if (exportPlaybackHistory) {
      exportData['playbackHistory'] = await _exportPlaybackHistoryData();
    }

    if (exportPlaylistSongs) {
      exportData['playlistSongs'] = await _exportPlaylistSongsData();
    }

    if (exportQueue) {
      exportData['queue'] = await _exportQueueData();
    }
    if (exportPlaybackStats) {
      exportData['playbackStats'] = await _exportPlaybackStatsData();
    }
    if (exportRecentPlaylists) {
      exportData['recentPlaylists'] = await _exportRecentPlaylistsData();
    }

    return exportData;
  }

  Future<String> createExportFile(Map<String, dynamic> exportData) async {
    final jsonString = json.encode(exportData);
    String directoryPath;

    if (defaultTargetPlatform == TargetPlatform.android) {
      directoryPath = '/storage/emulated/0/Download/Auralis/Exports';
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final directory = await getApplicationDocumentsDirectory();
      directoryPath = '${directory.path}/auralis/exports';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      directoryPath = directory.path;
    }

    final Directory exportDirectory = Directory(directoryPath);
    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    final file = File(
      '$directoryPath/auralis_export_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonString);
    return file.path;
  }

  Future<Map<String, dynamic>> readImportFile(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  Future<void> importSelectedData({
    required Map<String, dynamic> importData,
    required bool importCreatedPlaylists,
    required bool importSavedAlbums,
    required bool importSavedPlaylists,
    required bool importfavoriteArtists,
    required bool importfavoriteSongs,
    required bool importAppSettings,
    required bool importPlaybackHistory,
    required bool importPlaylistSongs,
    required bool importQueue,
    required bool importPlaybackStats,
    required bool importRecentPlaylists,
  }) async {
    if (importCreatedPlaylists && importData.containsKey('createdPlaylists')) {
      await _importCreatedPlaylistsData(importData['createdPlaylists']);
    }
    if (importSavedAlbums && importData.containsKey('savedAlbums')) {
      await _importSavedAlbumsData(importData['savedAlbums']);
    }
    if (importSavedPlaylists && importData.containsKey('savedPlaylists')) {
      await _importSavedPlaylistsData(importData['savedPlaylists']);
    }
    if (importfavoriteArtists && importData.containsKey('favoriteArtists')) {
      await _importfavoriteArtistsData(importData['favoriteArtists']);
    }
    if (importfavoriteSongs && importData.containsKey('favoriteSongs')) {
      await _importfavoriteSongsData(importData['favoriteSongs']);
    }
    if (importAppSettings && importData.containsKey('appSettings')) {
      await _importAppSettingsData(importData['appSettings']);
    }
    if (importPlaybackHistory && importData.containsKey('playbackHistory')) {
      await _importPlaybackHistoryData(importData['playbackHistory']);
    }

    if (importPlaylistSongs && importData.containsKey('playlistSongs')) {
      await _importPlaylistSongsData(importData['playlistSongs']);
    }

    if (importQueue && importData.containsKey('queue')) {
      await _importQueueData(importData['queue']);
    }
    if (importPlaybackStats && importData.containsKey('playbackStats')) {
      await _importPlaybackStatsData(importData['playbackStats']);
    }
    if (importRecentPlaylists && importData.containsKey('recentPlaylists')) {
      await _importRecentPlaylistsData(importData['recentPlaylists']);
    }
  }

  Future<List<dynamic>> _exportCreatedPlaylistsData() async {
    try {
      final box = Hive.box<String>('created_playlists');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting created playlists: $e');
      return [];
    }
  }

  Future<List<dynamic>> _exportSavedAlbumsData() async {
    try {
      final box = Hive.box<String>('saved_albums');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting saved albums: $e');
      return [];
    }
  }

  Future<List<dynamic>> _exportSavedPlaylistsData() async {
    try {
      final box = Hive.box<String>('saved_playlists');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting saved playlists: $e');
      return [];
    }
  }

  Future<List<dynamic>> _exportfavoriteArtistsData() async {
    try {
      final box = Hive.box<String>('favorite_artists');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting favorite artists: $e');
      return [];
    }
  }

  Future<List<dynamic>> _exportfavoriteSongsData() async {
    try {
      final box = Hive.box<String>('liked_songs');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting favorite songs: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _exportAppSettingsData() async {
    final box = await SettingsStorageService.getBox();
    return {
      'audioQuality': box.get('audioQuality'),
      'headsetControls': box.get('headsetControls'),
      'theme': box.get('theme'),
      'notifications': box.get('notifications'),
      'language': box.get('language'),
      'accentColor': box.get('accentColor'),
      'streamingQuality': box.get('streamingQuality'),
      'downloadingQuality': box.get('downloadingQuality'),
      'wifiOnlyDownloads': box.get('wifiOnlyDownloads'),
      'playbackHistoryEnabled': box.get('playbackHistoryEnabled'),
      'searchHistoryEnabled': box.get('searchHistoryEnabled'),
      'lyricsProvider': box.get('lyricsProvider'),
      'progressBarStyle': box.get('progressBarStyle'),
      'backgroundAnimationType': box.get('animationType'),
      'selectedCountryPlaylistId': box.get('selectedCountryPlaylistId'),
    };
  }

  Future<List<dynamic>> _exportPlaybackHistoryData() async {
    try {
      final box = Hive.box<String>('last_played');
      final values = box.values.cast<String>().toList();
      return values.map((e) => json.decode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error exporting playback history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _exportPlaylistSongsData() async {
    try {
      final box = Hive.box<String>('playlist_songs');
      final Map<String, dynamic> out = {};
      for (final key in box.keys) {
        final v = box.get(key as String);
        if (v == null) continue;
        try {
          out[key as String] = json.decode(v) as List<dynamic>;
        } catch (_) {}
      }
      return out;
    } catch (e) {
      debugPrint('Error exporting playlist songs: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _exportQueueData() async {
    try {
      final box = Hive.box<String>('queue_storage');
      final Map<String, dynamic> out = {};
      for (final key in box.keys) {
        final v = box.get(key as String);
        if (v == null) continue;
        try {
          out[key as String] = json.decode(v);
        } catch (_) {}
      }
      return out;
    } catch (e) {
      debugPrint('Error exporting queue data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _exportPlaybackStatsData() async {
    try {
      final box = Hive.box<String>('playback_stats');
      final Map<String, dynamic> out = {};
      for (final key in box.keys) {
        final v = box.get(key as String);
        if (v == null) continue;
        try {
          out[key as String] = json.decode(v) as Map<String, dynamic>;
        } catch (_) {}
      }
      return out;
    } catch (e) {
      debugPrint('Error exporting playback stats: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _exportRecentPlaylistsData() async {
    try {
      final box = Hive.box<String>('recent_playlists');
      final Map<String, dynamic> out = {};
      for (final key in box.keys) {
        final v = box.get(key as String);
        if (v == null) continue;
        try {
          out[key as String] = json.decode(v) as Map<String, dynamic>;
        } catch (_) {}
      }
      return out;
    } catch (e) {
      debugPrint('Error exporting recent playlists: $e');
      return {};
    }
  }

  Future<void> _importCreatedPlaylistsData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('created_playlists');
      await box.clear();
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final key = item['name']?.toString() ?? 'playlist_$i';
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing created playlists: $e');
    }
  }

  Future<void> _importSavedAlbumsData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('saved_albums');
      await box.clear();
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final key = item['albumId']?.toString() ?? 'album_$i';
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing saved albums: $e');
    }
  }

  Future<void> _importSavedPlaylistsData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('saved_playlists');
      await box.clear();
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final key = item['playlistId']?.toString() ?? 'playlist_$i';
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing saved playlists: $e');
    }
  }

  Future<void> _importfavoriteArtistsData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('favorite_artists');
      await box.clear();
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final key = item['artistId']?.toString() ?? 'artist_$i';
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing favorite artists: $e');
    }
  }

  Future<void> _importfavoriteSongsData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('liked_songs');
      await box.clear();
      for (int i = 0; i < data.length; i++) {
        final item = data[i] as Map<String, dynamic>;
        final key = item['id']?.toString() ?? 'song_$i';
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing favorite songs: $e');
    }
  }

  Future<void> _importAppSettingsData(Map<String, dynamic> data) async {
    final box = await SettingsStorageService.getBox();

    if (data.containsKey('audioQuality')) {
      await box.put('audioQuality', data['audioQuality'] ?? 'High');
    }
    if (data.containsKey('headsetControls')) {
      await box.put('headsetControls', data['headsetControls'] ?? true);
    }
    if (data.containsKey('theme')) {
      await box.put('theme', data['theme'] ?? 'Dark');
    }
    if (data.containsKey('notifications')) {
      await box.put('notifications', data['notifications'] ?? true);
    }
    if (data.containsKey('language')) {
      await box.put('language', data['language'] ?? 'English');
    }
    if (data.containsKey('accentColor')) {
      await box.put(
        'accentColor',
        data['accentColor'] ?? MainScreenColors.secondaryPink.value,
      );
    }
    if (data.containsKey('streamingQuality')) {
      await box.put('streamingQuality', data['streamingQuality'] ?? 'High');
    }
    if (data.containsKey('downloadingQuality')) {
      await box.put('downloadingQuality', data['downloadingQuality'] ?? 'High');
    }
    if (data.containsKey('wifiOnlyDownloads')) {
      await box.put('wifiOnlyDownloads', data['wifiOnlyDownloads'] ?? false);
    }
    if (data.containsKey('playbackHistoryEnabled')) {
      await box.put(
        'playbackHistoryEnabled',
        data['playbackHistoryEnabled'] ?? true,
      );
    }
    if (data.containsKey('searchHistoryEnabled')) {
      await box.put(
        'searchHistoryEnabled',
        data['searchHistoryEnabled'] ?? true,
      );
    }
    if (data.containsKey('lyricsProvider')) {
      await box.put('lyricsProvider', data['lyricsProvider'] ?? 'LRCLib');
    }
    if (data.containsKey('progressBarStyle')) {
      await box.put('progressBarStyle', data['progressBarStyle'] ?? 'Default');
    }
    if (data.containsKey('backgroundAnimationType')) {
      await box.put(
        'animationType',
        data['backgroundAnimationType'] ?? 'mixed',
      );
    }
    if (data.containsKey('selectedCountryPlaylistId')) {
      await box.put(
        'selectedCountryPlaylistId',
        data['selectedCountryPlaylistId'] ?? '',
      );
    }
  }

  Future<void> _importPlaybackHistoryData(List<dynamic> data) async {
    try {
      final box = Hive.box<String>('last_played');

      final existingValues = box.values.cast<String>().toList();
      final existingData = existingValues
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      final existingIds = Set<String>.from(
        existingData.map((item) => item['id'] as String),
      );

      final newData = data
          .cast<Map<String, dynamic>>()
          .where((item) => !existingIds.contains(item['id'] as String))
          .toList();

      for (final item in newData) {
        final key =
            item['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        await box.put(key, json.encode(item));
      }
    } catch (e) {
      debugPrint('Error importing playback history: $e');
    }
  }

  Future<void> _importPlaylistSongsData(Map<String, dynamic> data) async {
    try {
      final box = Hive.box<String>('playlist_songs');
      await box.clear();
      for (final entry in data.entries) {
        try {
          await box.put(entry.key, json.encode(entry.value));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error importing playlist songs: $e');
    }
  }

  Future<void> _importQueueData(Map<String, dynamic> data) async {
    try {
      final box = Hive.box<String>('queue_storage');
      await box.clear();
      for (final entry in data.entries) {
        try {
          await box.put(entry.key, json.encode(entry.value));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error importing queue data: $e');
    }
  }

  Future<void> _importPlaybackStatsData(Map<String, dynamic> data) async {
    try {
      final box = Hive.box<String>('playback_stats');
      await box.clear();
      for (final entry in data.entries) {
        try {
          await box.put(entry.key, json.encode(entry.value));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error importing playback stats: $e');
    }
  }

  Future<void> _importRecentPlaylistsData(Map<String, dynamic> data) async {
    try {
      final box = Hive.box<String>('recent_playlists');
      await box.clear();
      for (final entry in data.entries) {
        try {
          await box.put(entry.key, json.encode(entry.value));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error importing recent playlists: $e');
    }
  }

  bool isValidImportFile(String fileName) {
    return fileName.startsWith('auralis_export') && fileName.endsWith('.json');
  }

  Map<String, bool> detectAvailableDataTypes(Map<String, dynamic> importData) {
    return {
      'createdPlaylists':
          importData.containsKey('createdPlaylists') &&
          (importData['createdPlaylists'] as List).isNotEmpty,
      'savedAlbums':
          importData.containsKey('savedAlbums') &&
          (importData['savedAlbums'] as List).isNotEmpty,
      'savedPlaylists':
          importData.containsKey('savedPlaylists') &&
          (importData['savedPlaylists'] as List).isNotEmpty,
      'favoriteArtists':
          importData.containsKey('favoriteArtists') &&
          (importData['favoriteArtists'] as List).isNotEmpty,
      'favoriteSongs':
          importData.containsKey('favoriteSongs') &&
          (importData['favoriteSongs'] as List).isNotEmpty,
      'appSettings':
          importData.containsKey('appSettings') &&
          (importData['appSettings'] as Map).isNotEmpty,
      'playbackHistory':
          importData.containsKey('playbackHistory') &&
          (importData['playbackHistory'] as List).isNotEmpty,

      'playlistSongs':
          importData.containsKey('playlistSongs') &&
          (importData['playlistSongs'] as Map).isNotEmpty,

      'queue':
          importData.containsKey('queue') &&
          (importData['queue'] as Map).isNotEmpty,
      'playbackStats':
          importData.containsKey('playbackStats') &&
          (importData['playbackStats'] as Map).isNotEmpty,
      'recentPlaylists':
          importData.containsKey('recentPlaylists') &&
          (importData['recentPlaylists'] as Map).isNotEmpty,
    };
  }

  Map<String, int> getDataTypeCounts(Map<String, dynamic> importData) {
    return {
      'createdPlaylists': importData.containsKey('createdPlaylists')
          ? (importData['createdPlaylists'] as List).length
          : 0,
      'savedAlbums': importData.containsKey('savedAlbums')
          ? (importData['savedAlbums'] as List).length
          : 0,
      'savedPlaylists': importData.containsKey('savedPlaylists')
          ? (importData['savedPlaylists'] as List).length
          : 0,
      'favoriteArtists': importData.containsKey('favoriteArtists')
          ? (importData['favoriteArtists'] as List).length
          : 0,
      'favoriteSongs': importData.containsKey('favoriteSongs')
          ? (importData['favoriteSongs'] as List).length
          : 0,
      'appSettings': importData.containsKey('appSettings') ? 1 : 0,
      'playbackHistory': importData.containsKey('playbackHistory')
          ? (importData['playbackHistory'] as List).length
          : 0,

      'playlistSongs': importData.containsKey('playlistSongs')
          ? (importData['playlistSongs'] as Map).length
          : 0,

      'queue': importData.containsKey('queue')
          ? (importData['queue'] as Map).length
          : 0,
      'playbackStats': importData.containsKey('playbackStats')
          ? (importData['playbackStats'] as Map).length
          : 0,
      'recentPlaylists': importData.containsKey('recentPlaylists')
          ? (importData['recentPlaylists'] as Map).length
          : 0,
    };
  }
}
