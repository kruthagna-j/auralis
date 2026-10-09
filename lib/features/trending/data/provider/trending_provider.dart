import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/country_model.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/queued_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/yt-music-api.dart';
import '../../../../core/utils/duration_utils.dart';
import '../../../../shared/components/app_snackbar.dart';

part '../../../../generated/trending_provider.g.dart';

class TrendingProvider with ChangeNotifier {
  static const String top100GlobalPlaylistId =
      'PL4fGSI1pDJn5kI81J1fYWK5eZRl1zJ5kM';

  final List<Country> countries = [
    Country(
      name: 'India',
      flag: '🇮🇳',
      playlistId: 'PL4fGSI1pDJn40WjZ6utkIuj2rNg-7iGsq',
    ),
    Country(
      name: 'USA',
      flag: '🇺🇸',
      playlistId: 'PL4fGSI1pDJn69On1f-8NAvX_CYlx7QyZc',
    ),
    Country(
      name: 'UK',
      flag: '🇬🇧',
      playlistId: 'PL4fGSI1pDJn688ebB8czINn0_nov50e3A',
    ),
    Country(
      name: 'Canada',
      flag: '🇨🇦',
      playlistId: 'PL4fGSI1pDJn4IeWA7bBJYh__qgOCRMkIh',
    ),
    Country(
      name: 'Australia',
      flag: '🇦🇺',
      playlistId: 'PL4fGSI1pDJn44PMHPLYatj8rta8WYtZ8_',
    ),
    Country(
      name: 'Germany',
      flag: '🇩🇪',
      playlistId: 'PL4fGSI1pDJn4X-OicSCOy-dChXWdTgziQ',
    ),
    Country(
      name: 'France',
      flag: '🇫🇷',
      playlistId: 'PL4fGSI1pDJn50iCQRUVmgUjOrCggCQ9nR',
    ),
    Country(
      name: 'Japan',
      flag: '🇯🇵',
      playlistId: 'PL4fGSI1pDJn5FhDrWnRp2NLzJCoPliNgT',
    ),
    Country(
      name: 'South Korea',
      flag: '🇰🇷',
      playlistId: 'PL4fGSI1pDJn5S09aId3dUGp40ygUqmPGc',
    ),
    Country(
      name: 'Brazil',
      flag: '🇧🇷',
      playlistId: 'PL4fGSI1pDJn4Gs2meaJRo9O8PNYvhjHIg',
    ),
    Country(
      name: 'Mexico',
      flag: '🇲🇽',
      playlistId: 'PL4fGSI1pDJn5cDciLg1q9tabl7gzBZWOp',
    ),
    Country(
      name: 'Spain',
      flag: '🇪🇸',
      playlistId: 'PL4fGSI1pDJn4jhQB4kb9M36dvVmJQPt4T',
    ),
    Country(
      name: 'Italy',
      flag: '🇮🇹',
      playlistId: 'PL4fGSI1pDJn5BPviUFX4a3IMnAgyknC68',
    ),
    Country(
      name: 'Russia',
      flag: '🇷🇺',
      playlistId: 'PL4fGSI1pDJn6cLcPmcc9b_l8oM0aJtsqL',
    ),
    Country(
      name: 'Sweden',
      flag: '🇸🇪',
      playlistId: 'PL4fGSI1pDJn6l_eirqF_T40p1B8eJg2Pz',
    ),
    Country(
      name: 'Norway',
      flag: '🇳🇴',
      playlistId: 'PL4fGSI1pDJn5qlG8HM7Iq54JE8SROhAvM',
    ),
    Country(
      name: 'Netherlands',
      flag: '🇳🇱',
      playlistId: 'PL4fGSI1pDJn5i2QIxSEhPqSzhqsWhhrBJ',
    ),
    Country(
      name: 'Turkey',
      flag: '🇹🇷',
      playlistId: 'PL4fGSI1pDJn6rnJKpaAkK1XK8QUfa9KqP',
    ),
    Country(
      name: 'Argentina',
      flag: '🇦🇷',
      playlistId: 'PL4fGSI1pDJn403fWAsjzCMsLEgBTOa25K',
    ),
    Country(
      name: 'South Africa',
      flag: '🇿🇦',
      playlistId: 'PL4fGSI1pDJn79YvDK-Dq95SAW1V28wnns',
    ),
    Country(
      name: 'New Zealand',
      flag: '🇳🇿',
      playlistId: 'PL4fGSI1pDJn5yaX2-KEdvxQK0w938c-NX',
    ),
    Country(
      name: 'Ireland',
      flag: '🇮🇪',
      playlistId: 'PL4fGSI1pDJn574980IA4DVKDl8PDskrCj',
    ),
    Country(
      name: 'Switzerland',
      flag: '🇨🇭',
      playlistId: 'PL4fGSI1pDJn4KBb656ZmzFTCGK0eAv5bu',
    ),
    Country(
      name: 'Austria',
      flag: '🇦🇹',
      playlistId: 'PL4fGSI1pDJn42I7USCyNUQSjm-OlttqQf',
    ),
    Country(
      name: 'Belgium',
      flag: '🇧🇪',
      playlistId: 'PL4fGSI1pDJn47l8EXIwa8SCWWjh79rgMq',
    ),
    Country(
      name: 'Denmark',
      flag: '🇩🇰',
      playlistId: 'PL4fGSI1pDJn4YoCXjBl6kg3DhYgUJTSfw',
    ),
    Country(
      name: 'Finland',
      flag: '🇫🇮',
      playlistId: 'PL4fGSI1pDJn4ogogSnHUTIWMc_b7pHW9A',
    ),
    Country(
      name: 'Portugal',
      flag: '🇵🇹',
      playlistId: 'PL4fGSI1pDJn6G_VdIB6wxGYzuai0iA1hC',
    ),
    Country(
      name: 'Poland',
      flag: '🇵🇱',
      playlistId: 'PL4fGSI1pDJn69d7Zwro65Q7ORLxFVqr_U',
    ),
    Country(
      name: 'Czech Republic',
      flag: '🇨🇿',
      playlistId: 'PL4fGSI1pDJn4PsD5Tua9nTgnPsP0o9_0k',
    ),
    Country(
      name: 'Hungary',
      flag: '🇭🇺',
      playlistId: 'PL4fGSI1pDJn6-AkuEzkhgTBJq3Lm0Oolc',
    ),
    Country(
      name: 'Romania',
      flag: '🇷🇴',
      playlistId: 'PL4fGSI1pDJn6L8lQpfbnXpXUR71uksmP2',
    ),

    Country(
      name: 'Israel',
      flag: '🇮🇱',
      playlistId: 'PL4fGSI1pDJn5xFol0l4GwBnHYtXXMaY82',
    ),
    Country(
      name: 'Saudi Arabia',
      flag: '🇸🇦',
      playlistId: 'PL4fGSI1pDJn7b8BNLVP8XUrJCQp_loKZT',
    ),
    Country(
      name: 'UAE',
      flag: '🇦🇪',
      playlistId: 'PL4fGSI1pDJn4CDqdXJ4xP78Hh7X72vIXM',
    ),
    Country(
      name: 'Egypt',
      flag: '🇪🇬',
      playlistId: 'PL4fGSI1pDJn4EhpZkSSpdyWUet73FalVU',
    ),
    Country(
      name: 'Nigeria',
      flag: '🇳🇬',
      playlistId: 'PL4fGSI1pDJn5dHScZlGIe6TEoGzFv_qZE',
    ),
    Country(
      name: 'Kenya',
      flag: '🇰🇪',
      playlistId: 'PL4fGSI1pDJn5OYRHJhIu_bu7NRnkZ56ds',
    ),

    Country(
      name: 'Colombia',
      flag: '🇨🇴',
      playlistId: 'PL4fGSI1pDJn4ObZYxzctc1AM45GSWm2DC',
    ),
    Country(
      name: 'Chile',
      flag: '🇨🇱',
      playlistId: 'PL4fGSI1pDJn4M3llRxwSebRSrjFqeNN3x',
    ),
    Country(
      name: 'Peru',
      flag: '🇵🇪',
      playlistId: 'PL4fGSI1pDJn61j743B9r2LNeLCUUZsRMV',
    ),

    Country(
      name: 'Indonesia',
      flag: '🇮🇩',
      playlistId: 'PL4fGSI1pDJn5QPpj0R4vVgRWk8sSq549G',
    ),
  ];

  Country? _selectedCountry;
  final Map<String, List<SongInfo>> _trendingSongs = {};
  final Map<String, bool> _isLoading = {};

  Country? get selectedCountry => _selectedCountry;

  List<SongInfo> getTrendingSongs(String playlistId) =>
      _trendingSongs[playlistId] ?? [];
  bool isLoading(String playlistId) => _isLoading[playlistId] ?? false;

  TrendingProvider() {
    if (countries.isNotEmpty) {
      try {
        final settings = GetIt.I<SettingsProvider>();
        final savedPlaylistId = settings.selectedCountryPlaylistId;
        if (savedPlaylistId != null) {
          final matched = countries.firstWhere(
            (c) => c.playlistId == savedPlaylistId,
            orElse: () => countries.first,
          );
          _selectedCountry = matched;
        } else {
          _selectedCountry = countries.first;
        }
      } catch (_) {
        _selectedCountry = countries.first;
      }
    }
  }

  Future<void> setSelectedCountry(Country country) async {
    if (_selectedCountry != country) {
      _selectedCountry = country;
      notifyListeners();

      try {
        final settings = GetIt.I<SettingsProvider>();
        await settings.setSelectedCountryPlaylistId(country.playlistId);
      } catch (_) {}

      await refreshTrendingSongs(country.playlistId);
    }
  }

  Future<void> loadTrendingSongs(String playlistId) async {
    _isLoading[playlistId] = true;
    notifyListeners();

    try {
      _trendingSongs[playlistId] ??= [];

      await _loadTrendingSongsFromCache(playlistId);

      if (_trendingSongs[playlistId]!.isEmpty) {
        await _fetchTrendingSongsFromAPI(playlistId);
      }
    } catch (e) {
      debugPrint('Error loading trending songs for $playlistId: $e');

      if (_trendingSongs[playlistId]!.isEmpty) {
        await _fetchTrendingSongsFromAPI(playlistId);
      }
    } finally {
      _isLoading[playlistId] = false;
      notifyListeners();
    }
  }

  Future<void> _fetchTrendingSongsFromAPI(String playlistId) async {
    try {
      final result = await getPlaylistAlbumSongs(playlistId: playlistId);
      final songs = result['songs'] as List<dynamic>;

      _trendingSongs[playlistId] = songs.map((song) {
        final artists = (song['artists'] as List<dynamic>? ?? [])
            .map((a) => Artist(name: a['name'] ?? '', id: a['id'] ?? ''))
            .toList();
        final thumbnailsList = song['thumbnails'] as List<dynamic>? ?? [];
        final thumbnail = thumbnailsList.isNotEmpty
            ? thumbnailsList.reduce(
                (a, b) => (a['width'] as int? ?? 0) > (b['width'] as int? ?? 0)
                    ? a
                    : b,
              )
            : {'url': '', 'width': 0, 'height': 0};
        return SongInfo(
          videoId: song['videoId'] ?? '',
          name: song['title'] ?? '',
          artists: artists,
          thumbnails: [
            Thumbnail(
              url: thumbnail['url'],
              width: thumbnail['width'],
              height: thumbnail['height'],
            ),
          ],
          duration: DurationUtils.parseDuration(song['length'] as String?),
        );
      }).toList();

      await _saveTrendingSongsToCache(playlistId);
    } catch (e) {
      debugPrint('Error fetching trending songs from API for $playlistId: $e');
    }
  }

  Future<void> _saveTrendingSongsToCache(String playlistId) async {
    try {
      final box = await Hive.openBox<dynamic>('trending_songs_cache_v2');
      try {
        await box.put(
          playlistId,
          _trendingSongs[playlistId]!
              .map((song) => SongInfoDTO.fromSongInfo(song))
              .toList(),
        );
      } catch (e) {
        debugPrint('Error putting data to cache for $playlistId: $e');
        await box.delete(playlistId);
      }
    } catch (e) {
      debugPrint('Error opening box for saving $playlistId: $e');
    }
  }

  Future<void> _loadTrendingSongsFromCache(String playlistId) async {
    try {
      final box = await Hive.openBox<dynamic>('trending_songs_cache');
      dynamic cachedData;
      try {
        cachedData = box.get(playlistId);
      } catch (e) {
        debugPrint('Error getting cached data for $playlistId: $e');
        await box.delete(playlistId);
        cachedData = null;
      }
      if (cachedData != null) {
        try {
          _trendingSongs[playlistId] = (cachedData as List)
              .cast<SongInfoDTO>()
              .map((dto) => dto.toSongInfo())
              .toList();
          debugPrint(
            'Loaded ${_trendingSongs[playlistId]!.length} trending songs from cache for $playlistId',
          );
        } catch (e) {
          debugPrint('Error casting cached data for $playlistId: $e');
          await box.delete(playlistId);
        }
      }
    } catch (e) {
      debugPrint('Error opening box for $playlistId: $e');
    }
  }

  Future<void> refreshTrendingSongs(String playlistId) async {
    _isLoading[playlistId] = true;
    _trendingSongs.remove(playlistId);
    notifyListeners();

    try {
      await _fetchTrendingSongsFromAPI(playlistId);
    } catch (e) {
      debugPrint('Error refreshing trending songs for $playlistId: $e');
    } finally {
      _isLoading[playlistId] = false;
      notifyListeners();
    }
  }

  Future<void> playSong(
    SongInfo song,
    BuildContext context,
    String playlistId, {
    String? playlistName,
  }) async {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    try {
      final currentPlaylistSongs = _trendingSongs[playlistId] ?? [];
      final songIndex = currentPlaylistSongs.indexWhere(
        (s) => s.videoId == song.videoId,
      );

      String? computedPlaylistName = playlistName;
      if (computedPlaylistName == null) {
        if (playlistId == TrendingProvider.top100GlobalPlaylistId) {
          computedPlaylistName = 'Global Trending';
        } else {
          try {
            final country = countries.firstWhere(
              (c) => c.playlistId == playlistId,
            );
            if (country.name.isNotEmpty) {
              computedPlaylistName = '${country.name} Trending';
            }
          } catch (_) {}
        }
      }

      if (queueProvider.playlistId == playlistId) {
        if (songIndex != -1) {
          // queueProvider.setCurrentIndex(songIndex);
          await playerProvider.playerService.playSong(song);
        }
      } else {
        queueProvider.setQueue(
          currentPlaylistSongs,
          currentIndex: songIndex,
          playlistId: playlistId,
          playlistName: computedPlaylistName,
        );
        await playerProvider.playerService.playSong(song);
      }
    } catch (e) {
      debugPrint('Error playing song ${song.name}: $e');
      AppSnackBar.showError(context, 'Error playing song');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

@HiveType(typeId: 0)
class SongInfoDTO {
  @HiveField(0)
  final String videoId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<ArtistDTO> artists;
  @HiveField(3)
  final List<ThumbnailDTO> thumbnails;
  @HiveField(4)
  final int duration;

  SongInfoDTO({
    required this.videoId,
    required this.name,
    required this.artists,
    required this.thumbnails,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'name': name,
      'artists': artists.map((artist) => artist.toJson()).toList(),
      'thumbnails': thumbnails.map((thumbnail) => thumbnail.toJson()).toList(),
      'duration': duration,
    };
  }

  factory SongInfoDTO.fromJson(Map<String, dynamic> json) {
    return SongInfoDTO(
      videoId: json['videoId'],
      name: json['name'],
      artists: (json['artists'] as List)
          .map((artist) => ArtistDTO.fromJson(artist))
          .toList(),
      thumbnails: (json['thumbnails'] as List)
          .map((thumbnail) => ThumbnailDTO.fromJson(thumbnail))
          .toList(),
      duration: json['duration'],
    );
  }

  SongInfo toSongInfo() {
    return SongInfo(
      videoId: videoId,
      name: name,
      artists: artists.map((artist) => artist.toArtist()).toList(),
      thumbnails: thumbnails
          .map((thumbnail) => thumbnail.toThumbnail())
          .toList(),
      duration: Duration(milliseconds: duration),
    );
  }

  static SongInfoDTO fromSongInfo(SongInfo song) {
    return SongInfoDTO(
      videoId: song.videoId,
      name: song.name,
      artists: song.artists
          .map((artist) => ArtistDTO.fromArtist(artist))
          .toList(),
      thumbnails: song.thumbnails
          .map((thumbnail) => ThumbnailDTO.fromThumbnail(thumbnail))
          .toList(),
      duration: song.duration.inMilliseconds,
    );
  }
}

@HiveType(typeId: 1)
class ArtistDTO {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String id;

  ArtistDTO({required this.name, required this.id});

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id};
  }

  factory ArtistDTO.fromJson(Map<String, dynamic> json) {
    return ArtistDTO(name: json['name'], id: json['id']);
  }

  Artist toArtist() {
    return Artist(name: name, id: id);
  }

  static ArtistDTO fromArtist(Artist artist) {
    return ArtistDTO(name: artist.name, id: artist.id);
  }
}

@HiveType(typeId: 2)
class ThumbnailDTO {
  @HiveField(0)
  final String url;
  @HiveField(1)
  final int width;
  @HiveField(2)
  final int height;

  ThumbnailDTO({required this.url, required this.width, required this.height});

  Map<String, dynamic> toJson() {
    return {'url': url, 'width': width, 'height': height};
  }

  factory ThumbnailDTO.fromJson(Map<String, dynamic> json) {
    return ThumbnailDTO(
      url: json['url'],
      width: json['width'],
      height: json['height'],
    );
  }

  Thumbnail toThumbnail() {
    return Thumbnail(url: url, width: width, height: height);
  }

  static ThumbnailDTO fromThumbnail(Thumbnail thumbnail) {
    return ThumbnailDTO(
      url: thumbnail.url,
      width: thumbnail.width,
      height: thumbnail.height,
    );
  }
}
