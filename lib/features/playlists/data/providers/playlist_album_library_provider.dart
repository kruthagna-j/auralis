import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class PlaylistAlbumLibraryProvider with ChangeNotifier {
  static const String _playlistsBox = 'saved_playlists';
  static const String _albumsBox = 'saved_albums';
  static const String _createdBox = 'created_playlists';
  static const String _playlistSongsBox = 'playlist_songs';

  Box<String> get _playlists => Hive.box<String>(_playlistsBox);
  Box<String> get _albums => Hive.box<String>(_albumsBox);
  Box<String> get _createdPlaylistsBox => Hive.box<String>(_createdBox);
  Box<String> get _playlistSongs => Hive.box<String>(_playlistSongsBox);

  List<Map<String, dynamic>> _savedPlaylists = [];
  List<Map<String, dynamic>> _savedAlbums = [];
  List<Map<String, dynamic>> _createdPlaylists = [];
  bool _hasLoadedCreatedPlaylists = false;

  bool isPlaylistsLoading = false;
  bool isAlbumsLoading = false;
  bool isCreatedPlaylistsLoading = false;

  List<Map<String, dynamic>> get savedPlaylists => _savedPlaylists;
  List<Map<String, dynamic>> get savedAlbums => _savedAlbums;
  List<Map<String, dynamic>> get createdPlaylists => _createdPlaylists;
  bool get hasLoadedCreatedPlaylists => _hasLoadedCreatedPlaylists;

  Future<void> loadSavedPlaylists({bool notify = true}) async {
    if (notify) {
      isPlaylistsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final values = _playlists.values.cast<String>().toList();
      final newList = values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      newList.sort((a, b) {
        final aTs = (a['saved_at'] as int?) ?? 0;
        final bTs = (b['saved_at'] as int?) ?? 0;
        return bTs.compareTo(aTs);
      });

      _savedPlaylists = newList;
    } catch (e) {
      debugPrint('Error loading saved playlists: $e');
      _savedPlaylists = [];
    } finally {
      if (notify) {
        isPlaylistsLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }

  Future<void> loadSavedAlbums({bool notify = true}) async {
    if (notify) {
      isAlbumsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final values = _albums.values.cast<String>().toList();
      final newList = values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      newList.sort((a, b) {
        final aTs = (a['saved_at'] as int?) ?? 0;
        final bTs = (b['saved_at'] as int?) ?? 0;
        return bTs.compareTo(aTs);
      });

      _savedAlbums = newList;
    } catch (e) {
      debugPrint('Error loading saved albums: $e');
      _savedAlbums = [];
    } finally {
      if (notify) {
        isAlbumsLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }

  Future<void> loadCreatedPlaylists({bool notify = true}) async {
    if (notify) {
      isCreatedPlaylistsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final values = _createdPlaylistsBox.values.cast<String>().toList();
      final newList = values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      newList.sort((a, b) {
        final aTs =
            DateTime.tryParse(a['created'] ?? '')?.millisecondsSinceEpoch ?? 0;
        final bTs =
            DateTime.tryParse(b['created'] ?? '')?.millisecondsSinceEpoch ?? 0;
        return bTs.compareTo(aTs);
      });

      _createdPlaylists = newList;
    } catch (e) {
      debugPrint('Error loading created playlists: $e');
      _createdPlaylists = [];
    } finally {
      _hasLoadedCreatedPlaylists = true;
      if (notify) {
        isCreatedPlaylistsLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }

  Future<void> loadAll({bool notify = true}) async {
    if (notify) {
      isPlaylistsLoading = true;
      isAlbumsLoading = true;
      isCreatedPlaylistsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    await Future.wait([
      loadSavedPlaylists(notify: false),
      loadSavedAlbums(notify: false),

      loadCreatedPlaylistsWithThumbnails(notify: false),
    ]);

    if (notify) {
      isPlaylistsLoading = false;
      isAlbumsLoading = false;
      isCreatedPlaylistsLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> savePlaylist(Map<String, dynamic> playlist) async {
    final playlistId =
        (playlist['playlistId'] ??
                DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final item = Map<String, dynamic>.from(playlist);
    item['saved_at'] = DateTime.now().millisecondsSinceEpoch;
    await _playlists.put(playlistId, json.encode(item));
    await loadSavedPlaylists(notify: true);
  }

  Future<void> saveAlbum(Map<String, dynamic> album) async {
    final albumId =
        (album['albumId'] ?? DateTime.now().millisecondsSinceEpoch.toString())
            .toString();
    final item = Map<String, dynamic>.from(album);
    item['saved_at'] = DateTime.now().millisecondsSinceEpoch;
    await _albums.put(albumId, json.encode(item));
    await loadSavedAlbums(notify: true);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlists.delete(playlistId);
    await loadSavedPlaylists(notify: true);
  }

  Future<void> deleteAlbum(String albumId) async {
    await _albums.delete(albumId);
    await loadSavedAlbums(notify: true);
  }

  Future<void> saveCreatedPlaylist(String name, {String? thumbnail}) async {
    final exists = _createdPlaylistsBox.values.cast<String>().any((e) {
      final item = json.decode(e) as Map<String, dynamic>;
      return item['name'] == name;
    });

    if (exists) {
      throw Exception('Playlist already exists');
    }

    final item = {
      'name': name,
      'created': DateTime.now().toIso8601String(),
      'thumbnail': thumbnail,
    };

    await _createdPlaylistsBox.put(name, json.encode(item));
    await loadCreatedPlaylists(notify: true);
  }

  Future<void> deleteCreatedPlaylist(String name) async {
    await _createdPlaylistsBox.delete(name);

    await _playlistSongs.delete(name);
    await loadCreatedPlaylists(notify: true);
  }

  Future<void> saveSongToPlaylist(
    String playlistName,
    Map<String, dynamic> song,
  ) async {
    final existingJson = _playlistSongs.get(playlistName);
    List<dynamic> songs = [];
    if (existingJson != null) {
      try {
        songs = json.decode(existingJson) as List<dynamic>;
      } catch (_) {
        songs = [];
      }
    }
    songs.add(song);
    await _playlistSongs.put(playlistName, json.encode(songs));

    try {
      final createdJson = _createdPlaylistsBox.get(playlistName);
      if (createdJson != null) {
        final createdItem = json.decode(createdJson) as Map<String, dynamic>;
        final newThumb =
            song['thumbnail'] ?? await getLatestSongThumbnail(playlistName);
        createdItem['thumbnail'] = newThumb;
        await _createdPlaylistsBox.put(playlistName, json.encode(createdItem));
        final idx = _createdPlaylists.indexWhere(
          (p) => p['name'] == playlistName,
        );
        if (idx != -1) {
          _createdPlaylists[idx]['thumbnail'] = newThumb;
        }
      }
    } catch (e) {
      debugPrint(
        'Error updating created playlist thumbnail for $playlistName: $e',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> removeSongFromPlaylist(
    String playlistName,
    String songId,
  ) async {
    final existingJson = _playlistSongs.get(playlistName);
    if (existingJson == null) return;
    try {
      final songs = (json.decode(existingJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      songs.removeWhere((s) => s['id'].toString() == songId.toString());
      await _playlistSongs.put(playlistName, json.encode(songs));

      try {
        final latestThumb = await getLatestSongThumbnail(playlistName);
        final createdJson = _createdPlaylistsBox.get(playlistName);
        if (createdJson != null) {
          final createdItem = json.decode(createdJson) as Map<String, dynamic>;
          if (latestThumb != null) {
            createdItem['thumbnail'] = latestThumb;
          } else {
            createdItem.remove('thumbnail');
          }
          await _createdPlaylistsBox.put(
            playlistName,
            json.encode(createdItem),
          );
          final idx = _createdPlaylists.indexWhere(
            (p) => p['name'] == playlistName,
          );
          if (idx != -1) {
            if (latestThumb != null) {
              _createdPlaylists[idx]['thumbnail'] = latestThumb;
            } else {
              _createdPlaylists[idx].remove('thumbnail');
            }
          }
        }
      } catch (e) {
        debugPrint(
          'Error updating thumbnail after removal for $playlistName: $e',
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error removing song from $playlistName: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPlaylistSongs(
    String playlistName,
  ) async {
    final existingJson = _playlistSongs.get(playlistName);
    if (existingJson == null) return [];
    try {
      final list = (json.decode(existingJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return list;
    } catch (e) {
      debugPrint('Error decoding songs for $playlistName: $e');
      return [];
    }
  }

  Future<int> getSongCountForPlaylist(String playlistName) async {
    final songs = await getPlaylistSongs(playlistName);
    return songs.length;
  }

  Future<String?> getLatestSongThumbnail(String playlistName) async {
    final songs = await getPlaylistSongs(playlistName);
    if (songs.isEmpty) return null;

    return songs.last['thumbnail'];
  }

  Future<void> loadCreatedPlaylistsWithThumbnails({bool notify = true}) async {
    if (notify) {
      isCreatedPlaylistsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }

    try {
      final values = _createdPlaylistsBox.values.cast<String>().toList();
      final newList = values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      newList.sort((a, b) {
        final aTs =
            DateTime.tryParse(a['created'] ?? '')?.millisecondsSinceEpoch ?? 0;
        final bTs =
            DateTime.tryParse(b['created'] ?? '')?.millisecondsSinceEpoch ?? 0;
        return bTs.compareTo(aTs);
      });

      for (var playlist in newList) {
        final latestThumbnail = await getLatestSongThumbnail(playlist['name']);
        if (latestThumbnail != null) {
          playlist['thumbnail'] = latestThumbnail;
        }
      }

      _createdPlaylists = newList;
    } catch (e) {
      debugPrint('Error loading created playlists: $e');
      _createdPlaylists = [];
    } finally {
      _hasLoadedCreatedPlaylists = true;
      if (notify) {
        isCreatedPlaylistsLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }
}
