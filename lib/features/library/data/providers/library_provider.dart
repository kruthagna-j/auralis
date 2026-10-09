import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/favorite_song_provider.dart';
import '../../../../core/services/local_songs_service.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/providers/download_provider.dart';
import '../../../../core/providers/player_provider.dart';

enum LocalPermissionStatus { unknown, granted, denied, permanentlyDenied }

class LibraryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _lastPlayed = [];
  List<Map<String, dynamic>> _likedSongs = [];
  List<Map<String, dynamic>> _downloadedSongs = [];
  List<Map<String, dynamic>> _localSongs = [];
  bool _isLoading = true;
  bool _isLoadingLocalSongs = false;
  LocalPermissionStatus _localPermissionStatus = LocalPermissionStatus.unknown;
  final _collectionEquality = const DeepCollectionEquality();

  final PlayerProvider _playerProvider;
  final DownloadProvider _downloadProvider;
  final FavoriteSongProvider _favoriteSongProvider;
  final SettingsProvider _settingsProvider;

  List<Map<String, dynamic>> get lastPlayed => [..._lastPlayed];
  List<Map<String, dynamic>> get likedSongs => [..._likedSongs];
  List<Map<String, dynamic>> get downloadedSongs => [..._downloadedSongs];
  List<Map<String, dynamic>> get localSongs => [..._localSongs];
  bool get isLoading => _isLoading;
  bool get isLoadingLocalSongs => _isLoadingLocalSongs;
  LocalPermissionStatus get localPermissionStatus => _localPermissionStatus;

  LibraryProvider(
    this._playerProvider,
    this._downloadProvider,
    this._favoriteSongProvider,
    this._settingsProvider,
  ) {
    loadLibraryData();
    _playerProvider.addListener(_loadLastPlayed);
    _downloadProvider.addListener(_loadDownloadedSongs);
    _favoriteSongProvider.addListener(_loadLikedSongs);
    _settingsProvider.addListener(_loadLocalSongs);
  }

  @override
  void dispose() {
    _playerProvider.removeListener(_loadLastPlayed);
    _downloadProvider.removeListener(_loadDownloadedSongs);
    _favoriteSongProvider.removeListener(_loadLikedSongs);
    _settingsProvider.removeListener(_loadLocalSongs);
    super.dispose();
  }

  Future<void> _requestPermission() async {
    if (!Platform.isAndroid) {
      _localPermissionStatus = LocalPermissionStatus.granted;
      notifyListeners();
      await _loadLocalSongs();
      return;
    }

    final permission = await _androidAudioPermission();
    var status = await permission.status;

    // Request during the normal library startup flow so a fresh install can
    // populate Local Music without requiring the user to find a hidden action.
    if (status.isDenied) {
      status = await permission.request();
    }

    if (status.isGranted) {
      _localPermissionStatus = LocalPermissionStatus.granted;
      notifyListeners();
      await _loadLocalSongs();
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      _localPermissionStatus = LocalPermissionStatus.permanentlyDenied;
      notifyListeners();
    } else {
      _localPermissionStatus = LocalPermissionStatus.denied;
      notifyListeners();
    }
  }

  Future<Permission> _androidAudioPermission() async {
    final sdkInt = await _getAndroidVersion();
    // Android 13+ has the dedicated READ_MEDIA_AUDIO runtime permission.
    // Android 10-12 still use READ_EXTERNAL_STORAGE for this purpose; the
    // MANAGE_EXTERNAL_STORAGE special access is not required for MediaStore.
    return sdkInt >= 33 ? Permission.audio : Permission.storage;
  }

  Future<void> requestLocalPermission() async {
    if (Platform.isAndroid) {
      final permission = await _androidAudioPermission();

      if (_localPermissionStatus == LocalPermissionStatus.permanentlyDenied) {
        await openAppSettings();
        final status = await permission.status;
        if (status.isGranted) {
          _localPermissionStatus = LocalPermissionStatus.granted;
          notifyListeners();
          await _loadLocalSongs();
        } else if (status.isPermanentlyDenied || status.isRestricted) {
          _localPermissionStatus = LocalPermissionStatus.permanentlyDenied;
          notifyListeners();
        } else {
          _localPermissionStatus = LocalPermissionStatus.denied;
          notifyListeners();
        }
      } else {
        final status = await permission.request();
        if (status.isGranted) {
          _localPermissionStatus = LocalPermissionStatus.granted;
          notifyListeners();
          await _loadLocalSongs();
        } else if (status.isPermanentlyDenied || status.isRestricted) {
          _localPermissionStatus = LocalPermissionStatus.permanentlyDenied;
          notifyListeners();
        } else {
          _localPermissionStatus = LocalPermissionStatus.denied;
          notifyListeners();
        }
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  Future<void> _loadLocalSongs() async {
    if (Platform.isAndroid &&
        _localPermissionStatus != LocalPermissionStatus.granted) {
      return;
    }

    _isLoadingLocalSongs = true;
    notifyListeners();
    try {
      List<Map<String, dynamic>> songs = [];

      if (Platform.isWindows || Platform.isLinux) {
        final userDirectory = Platform.environment['USERPROFILE'];
        final List<Directory> dirsToScan = [];

        if (userDirectory != null) {
          dirsToScan.add(
            Directory('$userDirectory${Platform.pathSeparator}Music'),
          );
          dirsToScan.add(
            Directory('$userDirectory${Platform.pathSeparator}Downloads'),
          );
        }

        for (final folder in _settingsProvider.includedFolders) {
          final normalized = folder.replaceAll('/', Platform.pathSeparator);
          final dir = Directory(normalized);
          if (!dirsToScan.any((d) => d.path == dir.path)) dirsToScan.add(dir);
        }

        final seen = <String>{};
        for (final dir in dirsToScan) {
          try {
            if (!dir.existsSync()) continue;
            final audioFiles = await _findAudioFiles(dir);
            for (final file in audioFiles) {
              if (!seen.add(file.path)) continue;

              try {
                final metadata = await MetadataGod.readMetadata(
                  file: file.path,
                );
                final duration = metadata.duration?.inSeconds ?? 0;

                if (duration >= _settingsProvider.minSongDuration) {
                  songs.add({
                    'id': file.path.hashCode.toString(),
                    'title':
                        metadata.title ??
                        file.path.split(Platform.pathSeparator).last,
                    'artist': metadata.artist ?? 'unknown_artist'.tr(),
                    'duration': duration,
                    'isLocal': true,
                    'localPath': file.path,
                    'albumId': metadata.album ?? '',
                    'thumbnail': null,
                  });
                }
              } catch (e) {
                debugPrint('Error reading metadata for ${file.path}: $e');
                final fileName = file.path.split(Platform.pathSeparator).last;
                songs.add({
                  'id': file.path.hashCode.toString(),
                  'title': fileName,
                  'artist': 'unknown_artist'.tr(),
                  'duration': 0,
                  'isLocal': true,
                  'localPath': file.path,
                  'albumId': '',
                  'thumbnail': null,
                });
              }
            }
          } catch (e) {
            debugPrint('Failed scanning directory ${dir.path}: $e');
          }
        }
      } else {
        List<Map<String, dynamic>> allSongs;
        try {
          final service = LocalSongsService();
          allSongs = await service.querySongs();
        } catch (e) {
          debugPrint('Error querying songs: $e');
          _isLoadingLocalSongs = false;
          notifyListeners();
          return;
        }

        songs = allSongs
            .where(
              (song) =>
                  ((song['durationMs'] as int?) ?? 0) >=
                  (_settingsProvider.minSongDuration * 1000),
            )
            .map(
              (song) => {
                'id': song['id'].toString(),
                'title': song['title'] ?? 'Unknown',
                'artist': song['artist'] ?? 'unknown_artist'.tr(),
                'duration': song['duration'] ?? 0,
                'isLocal': true,
                'localPath': song['data'] ?? '',
                'albumId': song['albumId'],
                'thumbnail': null,
              },
            )
            .where((song) => (song['localPath'] as String).isNotEmpty)
            .toList();
      }

      final includedFolders = _settingsProvider.includedFolders;
      final excludedFolders = _settingsProvider.excludedFolders;

      if (includedFolders.isNotEmpty) {
        songs = songs.where((song) {
          final rawPath = song['localPath'] as String;
          final path = rawPath
              .replaceAll('/', Platform.pathSeparator)
              .toLowerCase();

          if (Platform.isWindows || Platform.isLinux) {
            return includedFolders.any((folder) {
              final norm = folder
                  .replaceAll('/', Platform.pathSeparator)
                  .toLowerCase();
              return path.startsWith(norm);
            });
          } else {
            return includedFolders.any(
                  (folder) => rawPath.startsWith(folder),
                ) ||
                path.contains('/storage/emulated/0/Download') ||
                path.contains('/storage/emulated/0/Music');
          }
        }).toList();
      }

      if (excludedFolders.isNotEmpty) {
        songs = songs.where((song) {
          final path = song['localPath'] as String;
          return !excludedFolders.any((folder) => path.startsWith(folder));
        }).toList();
      }

      final includedExtensions = _settingsProvider.includedExtensions;
      final excludedExtensions = _settingsProvider.excludedExtensions;

      if (includedExtensions.isNotEmpty) {
        songs = songs.where((song) {
          final path = song['localPath'] as String;
          final extension = path.split('.').last.toLowerCase();
          return includedExtensions.contains('.$extension');
        }).toList();
      }

      if (excludedExtensions.isNotEmpty) {
        songs = songs.where((song) {
          final path = song['localPath'] as String;
          final extension = path.split('.').last.toLowerCase();
          return !excludedExtensions.contains('.$extension');
        }).toList();
      }

      _localSongs = songs;
      debugPrint('Loaded ${_localSongs.length} local songs');
      _isLoadingLocalSongs = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading local songs: $e');
      _isLoadingLocalSongs = false;
      notifyListeners();
    }
  }

  Future<List<File>> _findAudioFiles(Directory directory) async {
    final List<File> audioFiles = [];
    try {
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        try {
          if (entity is File && _isAudioFile(entity)) {
            audioFiles.add(entity);
          }
        } catch (e) {
          debugPrint('Skipping entry ${entity.path}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error listing directory ${directory.path}: $e');
    }
    return audioFiles;
  }

  bool _isAudioFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    if (Platform.isWindows || Platform.isLinux) {
      return ['mp3', 'wav', 'aac', 'flac', 'm4a'].contains(extension);
    }
    return ['mp3', 'wav', 'aac', 'ogg', 'flac', 'm4a'].contains(extension);
  }

  Future<void> loadLibraryData() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _loadLastPlayed(),
      _loadLikedSongs(),
      _loadDownloadedSongs(),
    ]);
    _isLoading = false;
    notifyListeners();

    await _requestPermission();
  }

  Future<void> _loadLastPlayed() async {
    try {
      _lastPlayed = _playerProvider.lastPlayedSongs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading last played: $e');
      _lastPlayed = [];
    }
  }

  Future<void> _loadLikedSongs() async {
    try {
      _likedSongs = _favoriteSongProvider.likedSongs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading liked songs: $e');
      _likedSongs = [];
    }
  }

  Future<void> _loadDownloadedSongs() async {
    final songs = await _downloadProvider.getDownloadedSongs();
    if (!_collectionEquality.equals(_downloadedSongs, songs)) {
      _downloadedSongs = songs;
      notifyListeners();
    }
  }

  Future<void> refreshLibraryData() async {
    await loadLibraryData();
  }
}
