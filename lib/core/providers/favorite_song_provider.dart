import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../models/song_model.dart';

class FavoriteSongProvider with ChangeNotifier {
  static const String _boxName = 'liked_songs';
  Box<String> get _box => Hive.box<String>(_boxName);

  final _collectionEquality = const DeepCollectionEquality();

  bool _isCurrentSongLiked = false;
  SongInfo? _currentSong;
  List<Map<String, dynamic>> _likedSongs = [];
  bool _isLoadingLikedSongs = false;

  bool get isCurrentSongLiked => _isCurrentSongLiked;
  List<Map<String, dynamic>> get likedSongs => _likedSongs;
  bool get isLoadingLikedSongs => _isLoadingLikedSongs;

  void updateCurrentSongStatusWithoutNotify(SongInfo? song) {
    _currentSong = song;
    _isCurrentSongLiked = song != null && _box.containsKey(song.videoId);
  }

  void setCurrentSong(SongInfo? song) {
    _currentSong = song;
    final isLiked = song != null && _box.containsKey(song.videoId);
    if (_isCurrentSongLiked != isLiked) {
      _isCurrentSongLiked = isLiked;
      notifyListeners();
    }
  }

  Future<void> toggleLike() async {
    if (_currentSong == null) return;

    await _toggleLikeInBox(_currentSong!);

    final isLiked = _box.containsKey(_currentSong!.videoId);
    if (_isCurrentSongLiked != isLiked) {
      _isCurrentSongLiked = isLiked;
      notifyListeners();
    }

    await loadLikedSongs(notify: true);
  }

  bool isSongLiked(String songId) => _box.containsKey(songId);

  Future<void> toggleLikeForSong(SongInfo song) async {
    await _toggleLikeInBox(song);
    if (_currentSong != null && _currentSong!.videoId == song.videoId) {
      _isCurrentSongLiked = _box.containsKey(song.videoId);
      notifyListeners();
    }

    await loadLikedSongs(notify: true);
  }

  Future<void> removeLikedSong(String songId) async {
    if (_box.containsKey(songId)) {
      await _box.delete(songId);
      await loadLikedSongs(notify: true);
    }
  }

  Future<void> loadLikedSongs({bool notify = true}) async {
    if (notify) {
      _isLoadingLikedSongs = true;
      notifyListeners();
    }

    try {
      final newLikedSongs = await _getLikedSongsFromBox();
      if (!_collectionEquality.equals(_likedSongs, newLikedSongs)) {
        _likedSongs = newLikedSongs;
      }
    } catch (e) {
      debugPrint('Error loading liked songs: $e');
      _likedSongs = [];
    } finally {
      if (notify) {
        _isLoadingLikedSongs = false;
        notifyListeners();
      }
    }
  }

  Future<void> _toggleLikeInBox(SongInfo song) async {
    final songId = song.videoId;
    if (_box.containsKey(songId)) {
      await _box.delete(songId);
      return;
    }

    final songData = {
      'id': song.videoId,
      'title': song.name,
      'thumbnail': song.thumbnails.isNotEmpty ? song.thumbnails.first.url : '',
      'artists': song.artists.map((a) => {'name': a.name, 'id': a.id}).toList(),
      'duration': song.duration.inSeconds,
      'liked_at': DateTime.now().millisecondsSinceEpoch,
    };

    final songJson = json.encode(songData);
    await _box.put(songId, songJson);
  }

  Future<List<Map<String, dynamic>>> _getLikedSongsFromBox() async {
    final values = _box.values.cast<String>();
    final songs = values.map((s) => json.decode(s) as Map<String, dynamic>).map(
      (song) {
        if (song['artists'] == null && song['artist'] != null) {
          final artistNames = (song['artist'] as String).split(' & ');
          final artistIds = song['artistIds'] as List<dynamic>? ?? [];
          song['artists'] = List.generate(
            artistNames.length,
            (i) => {
              'name': artistNames[i],
              'id': i < artistIds.length ? artistIds[i] : '',
            },
          );
          song.remove('artist');
          song.remove('artistIds');
        }
        return song;
      },
    ).toList();

    songs.sort((a, b) {
      final aTs = (a['liked_at'] as int?) ?? 0;
      final bTs = (b['liked_at'] as int?) ?? 0;
      return bTs.compareTo(aTs);
    });

    return songs;
  }
}
