import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class FavoriteArtistProvider with ChangeNotifier {
  final _collectionEquality = const DeepCollectionEquality();
  static const String _boxName = 'favorite_artists';

  Box<String> get _box => Hive.box<String>(_boxName);

  List<Map<String, dynamic>> _favoriteArtists = [];
  bool isFavoriteArtistsLoading = false;

  List<Map<String, dynamic>> get favoriteArtists => _favoriteArtists;

  Future<void> loadFavoriteArtists({bool notify = true}) async {
    if (notify) {
      isFavoriteArtistsLoading = true;
      notifyListeners();
    }

    try {
      final values = _box.values.cast<String>().toList();
      final newArtists = values
          .map((e) => json.decode(e) as Map<String, dynamic>)
          .toList();

      if (!_collectionEquality.equals(_favoriteArtists, newArtists)) {
        _favoriteArtists = newArtists;
      }
    } catch (e) {
      debugPrint('Error loading favorite artists: $e');
      _favoriteArtists = [];
    } finally {
      if (notify) {
        isFavoriteArtistsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> toggleFavorite(dynamic artist) async {
    final artistId = artist.artistId?.toString() ?? '';
    final existing = _box.get(artistId);

    final artistData = {
      'name': artist.name,
      'artistId': artistId,
      'thumbnailUrl': artist.thumbnails?.last.url,
      'liked_at': DateTime.now().millisecondsSinceEpoch,
    };

    final artistJson = json.encode(artistData);

    final isAlreadyFavorite = existing != null;

    if (isAlreadyFavorite) {
      await _box.delete(artistId);
    } else {
      await _box.put(artistId, artistJson);
    }

    await loadFavoriteArtists(notify: true);
    return !isAlreadyFavorite;
  }

  Future<bool> isArtistFavorite(String artistId) async {
    await loadFavoriteArtists(notify: false);
    return _favoriteArtists.any((artist) => artist['artistId'] == artistId);
  }

  Future<void> removeFavorite(String artistId) async {
    await _box.delete(artistId);
    await loadFavoriteArtists(notify: true);
  }

  Future<void> editFavorite(String artistId, String newName) async {
    final existing = _box.get(artistId);
    if (existing == null) return;

    final decoded = json.decode(existing) as Map<String, dynamic>;
    decoded['name'] = newName;
    await _box.put(artistId, json.encode(decoded));
    await loadFavoriteArtists(notify: true);
  }
}
