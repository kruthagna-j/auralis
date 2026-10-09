class SongInfo {
  final String videoId;
  final String name;
  final List<Artist> artists;
  final List<Thumbnail> thumbnails;
  final Duration duration;

  SongInfo({
    required this.videoId,
    required this.name,
    required this.artists,
    required this.thumbnails,
    required this.duration,
  });
}

class Artist {
  final String name;
  final String id;

  Artist({required this.name, required this.id});
}

class Thumbnail {
  final String url;
  final int width;
  final int height;

  Thumbnail({required this.url, required this.width, required this.height});
}

class ArtistInfo {
  final String id;
  final String name;
  final String thumbnailUrl;

  ArtistInfo({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });
}
