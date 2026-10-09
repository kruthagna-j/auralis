import 'package:collection/collection.dart';
import 'package:dart_ytmusic_api/types.dart';
import 'package:flutter/material.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import '../../../../core/models/song_model.dart';
import '../../../../core/providers/connectivity_provider.dart';

part '../../../../generated/home_screen_provider.g.dart';

class HomeScreenProvider with ChangeNotifier {
  final YTMusic _ytMusic = GetIt.I<YTMusic>();
  final _collectionEquality = const DeepCollectionEquality();

  bool isHomeSectionsLoading = true;
  String _error = '';
  bool _isOfflineMode = false;

  List<dynamic> _homeSections = [];

  String get error => _error;
  List<dynamic> get homeSections => _homeSections;
  bool get isOfflineMode => _isOfflineMode;

  ConnectivityProvider? get _connectivityProvider {
    try {
      return GetIt.I<ConnectivityProvider>();
    } catch (e) {
      return null;
    }
  }

  Future<void> initialize() async {
    try {
      await loadHomeSections();
    } catch (e) {
      _error = 'Failed to initialize YT Music';
      debugPrint(_error);
      isHomeSectionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHomeSections({bool forceRefresh = false}) async {
    isHomeSectionsLoading = true;
    notifyListeners();

    if (forceRefresh) {
      await _fetchHomeSectionsFromAPI(notify: false);
    } else {
      await _loadHomeSectionsFromCache(notify: false);
    }

    isHomeSectionsLoading = false;
    notifyListeners();
  }

  Future<void> refreshData() async {
    await loadHomeSections(forceRefresh: true);
  }

  Future<void> saveHomeSections() async {
    try {
      final box = await Hive.openBox<dynamic>('home_sections_cache');
      await box.put(
        'homeSections',
        _homeSections
            .map((section) => HomeSectionDTO.fromHomeSection(section))
            .toList(),
      );
      await box.put('lastFetchTime', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving home sections: $e');
    }
  }

  Future<void> loadSavedHomeSections() async {
    try {
      final box = await Hive.openBox<dynamic>('home_sections_cache');
      final cachedData = box.get('homeSections');
      if (cachedData != null) {
        final newSections = (cachedData as List)
            .cast<HomeSectionDTO>()
            .map((dto) => dto.toHomeSection())
            .toList();
        if (!_collectionEquality.equals(_homeSections, newSections)) {
          _homeSections = newSections;
        }
      }
      debugPrint('Loaded home sections from cache');
    } catch (e) {
      debugPrint('Error loading home sections: $e');
    }
  }

  Future<void> _loadHomeSectionsFromCache({bool notify = true}) async {
    if (notify) {
      isHomeSectionsLoading = true;
      notifyListeners();
    }
    try {
      await loadSavedHomeSections();

      final box = await Hive.openBox<dynamic>('home_sections_cache');
      final lastFetchTime = box.get('lastFetchTime') as int?;
      bool needsRefresh = false;

      if (lastFetchTime != null) {
        final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
        if (DateTime.now().difference(lastFetch).inHours >= 4) {
          needsRefresh = true;
          debugPrint('Cache is older than 4 hours, fetching from API.');
        }
      } else if (_homeSections.isNotEmpty) {
        needsRefresh = true;
      }

      if ((_homeSections.isEmpty || needsRefresh) &&
          (_connectivityProvider?.canPerformNetworkOperations() ?? false)) {
        await _fetchHomeSectionsFromAPI(notify: false);
      } else if (_homeSections.isEmpty) {
        _isOfflineMode = true;
        _error = 'No cached data available. Please connect to internet.';
        debugPrint('No cached data and no internet connection');
      } else {
        _isOfflineMode =
            !(_connectivityProvider?.canPerformNetworkOperations() ?? false);
      }
    } catch (e) {
      debugPrint('Error loading home sections from cache: $e');
      _homeSections = [];
      _isOfflineMode = true;
    } finally {
      if (notify) {
        isHomeSectionsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchHomeSectionsFromAPI({bool notify = true}) async {
    if (!(_connectivityProvider?.canPerformNetworkOperations() ?? false)) {
      debugPrint('No internet connection - skipping API call');
      _isOfflineMode = true;
      return;
    }

    debugPrint('loading home sections from api');
    if (notify) {
      isHomeSectionsLoading = true;
      notifyListeners();
    }
    try {
      final sections = await _ytMusic.getHomeSections();
      final newSections = sections
          .where(
            (section) =>
                section.contents.isNotEmpty && section.title.isNotEmpty,
          )
          .toList();

      if (!_collectionEquality.equals(_homeSections, newSections)) {
        _homeSections = newSections;
        await saveHomeSections();
      }
      _isOfflineMode = false;
      _error = '';
      debugPrint('Loaded home sections from api');
    } catch (e) {
      debugPrint('Error fetching home sections from API: $e');
      _isOfflineMode = true;
      _error = 'Failed to load data from server';
    } finally {
      if (notify) {
        isHomeSectionsLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ContentItem {
  final String name;
  final String contentType;
  final String playlistId;
  final List<Thumbnail> thumbnails;

  ContentItem({
    required this.name,
    required this.contentType,
    required this.playlistId,
    required this.thumbnails,
  });
}

@HiveType(typeId: 3)
class HomeSectionDTO {
  @HiveField(0)
  final String title;
  @HiveField(1)
  final List<ContentItemDTO> contents;

  HomeSectionDTO({required this.title, required this.contents});

  factory HomeSectionDTO.fromHomeSection(HomeSection section) {
    return HomeSectionDTO(
      title: section.title,
      contents: section.contents.map((content) {
        if (content is AlbumDetailed) {
          return AlbumDetailedDTO.fromAlbumDetailed(content);
        } else if (content is PlaylistDetailed) {
          return PlaylistDetailedDTO.fromPlaylistDetailed(content);
        }
        throw Exception('Unknown content type for DTO conversion');
      }).toList(),
    );
  }

  HomeSection toHomeSection() {
    return HomeSection(
      title: title,
      contents: contents.map((dto) {
        if (dto is AlbumDetailedDTO) {
          return dto.toAlbumDetailed();
        } else if (dto is PlaylistDetailedDTO) {
          return dto.toPlaylistDetailed();
        }
        throw Exception('Unknown content type for original conversion');
      }).toList(),
    );
  }
}

@HiveType(typeId: 8)
class ContentItemDTO {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String contentType;
  @HiveField(2)
  final String playlistId;
  @HiveField(3)
  final List<ThumbnailFullDTO> thumbnails;

  ContentItemDTO({
    required this.name,
    required this.contentType,
    required this.playlistId,
    required this.thumbnails,
  });
}

@HiveType(typeId: 6)
class AlbumDetailedDTO extends ContentItemDTO {
  @HiveField(4)
  final ArtistBasicDTO artist;
  @HiveField(5)
  final String albumId;

  AlbumDetailedDTO({
    required String name,
    required String contentType,
    required String playlistId,
    required List<ThumbnailFullDTO> thumbnails,
    required this.artist,
    required this.albumId,
  }) : super(
         name: name,
         contentType: contentType,
         playlistId: playlistId,
         thumbnails: thumbnails,
       );

  factory AlbumDetailedDTO.fromAlbumDetailed(AlbumDetailed album) {
    return AlbumDetailedDTO(
      name: album.name,
      contentType: album.type,
      playlistId: album.playlistId,
      thumbnails: album.thumbnails
          .map((t) => ThumbnailFullDTO.fromThumbnailFull(t))
          .toList(),
      artist: ArtistBasicDTO.fromArtistBasic(album.artist),
      albumId: album.albumId,
    );
  }

  AlbumDetailed toAlbumDetailed() {
    return AlbumDetailed(
      name: name,
      type: contentType,
      playlistId: playlistId,
      thumbnails: thumbnails.map((t) => t.toThumbnailFull()).toList(),
      artist: artist.toArtistBasic(),
      albumId: albumId,
    );
  }
}

@HiveType(typeId: 7)
class PlaylistDetailedDTO extends ContentItemDTO {
  PlaylistDetailedDTO({
    required String name,
    required String contentType,
    required String playlistId,
    required List<ThumbnailFullDTO> thumbnails,
  }) : super(
         name: name,
         contentType: contentType,
         playlistId: playlistId,
         thumbnails: thumbnails,
       );

  factory PlaylistDetailedDTO.fromPlaylistDetailed(PlaylistDetailed playlist) {
    return PlaylistDetailedDTO(
      name: playlist.name,
      contentType: playlist.type,
      playlistId: playlist.playlistId,
      thumbnails: playlist.thumbnails
          .map((t) => ThumbnailFullDTO.fromThumbnailFull(t))
          .toList(),
    );
  }

  PlaylistDetailed toPlaylistDetailed() {
    return PlaylistDetailed(
      name: name,
      type: contentType,
      playlistId: playlistId,
      thumbnails: thumbnails.map((t) => t.toThumbnailFull()).toList(),
      artist: ArtistBasic(name: ''),
    );
  }
}

@HiveType(typeId: 4)
class ArtistBasicDTO {
  @HiveField(0)
  final String name;

  ArtistBasicDTO({required this.name});

  factory ArtistBasicDTO.fromArtistBasic(ArtistBasic artist) {
    return ArtistBasicDTO(name: artist.name);
  }

  ArtistBasic toArtistBasic() {
    return ArtistBasic(name: name);
  }
}

@HiveType(typeId: 5)
class ThumbnailFullDTO {
  @HiveField(0)
  final String url;
  @HiveField(1)
  final int width;
  @HiveField(2)
  final int height;

  ThumbnailFullDTO({
    required this.url,
    required this.width,
    required this.height,
  });

  factory ThumbnailFullDTO.fromThumbnailFull(ThumbnailFull thumbnail) {
    return ThumbnailFullDTO(
      url: thumbnail.url,
      width: thumbnail.width,
      height: thumbnail.height,
    );
  }

  ThumbnailFull toThumbnailFull() {
    return ThumbnailFull(url: url, width: width, height: height);
  }
}
