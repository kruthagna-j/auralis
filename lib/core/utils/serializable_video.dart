import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SerializableVideo {
  final SerializableVideoId id;
  final String title;
  final String author;
  final SerializableChannelId channelId;
  final DateTime? uploadDate;
  final String? uploadDateRaw;
  final DateTime? publishDate;
  final String description;
  final Duration? duration;
  final SerializableThumbnailSet thumbnails;
  final List<String>? keywords;
  final SerializableEngagement engagement;
  final bool isLive;

  SerializableVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    this.uploadDate,
    this.uploadDateRaw,
    this.publishDate,
    required this.description,
    this.duration,
    required this.thumbnails,
    this.keywords,
    required this.engagement,
    required this.isLive,
  });

  factory SerializableVideo.fromVideo(Video video) {
    return SerializableVideo(
      id: SerializableVideoId.fromVideoId(video.id),
      title: video.title,
      author: video.author,
      channelId: SerializableChannelId.fromChannelId(video.channelId),
      uploadDate: video.uploadDate,
      uploadDateRaw: video.uploadDateRaw,
      publishDate: video.publishDate,
      description: video.description,
      duration: video.duration,
      thumbnails: SerializableThumbnailSet.fromThumbnailSet(video.thumbnails),
      keywords: video.keywords.toList(),
      engagement: SerializableEngagement.fromEngagement(video.engagement),
      isLive: video.isLive,
    );
  }

  Video toVideo() {
    return Video(
      id.toVideoId(),
      title,
      author,
      channelId.toChannelId(),
      uploadDate,
      uploadDateRaw,
      publishDate,
      description,
      duration,
      thumbnails.toThumbnailSet(id.value),
      keywords ?? [],
      engagement.toEngagement(),
      isLive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toJson(),
      'title': title,
      'author': author,
      'channelId': channelId.toJson(),
      'uploadDate': uploadDate?.toIso8601String(),
      'uploadDateRaw': uploadDateRaw,
      'publishDate': publishDate?.toIso8601String(),
      'description': description,
      'duration': duration?.inSeconds,
      'thumbnails': thumbnails.toJson(),
      'keywords': keywords,
      'engagement': engagement.toJson(),
      'isLive': isLive,
    };
  }

  factory SerializableVideo.fromJson(Map<String, dynamic> json) {
    return SerializableVideo(
      id: SerializableVideoId.fromJson(json['id']),
      title: json['title'],
      author: json['author'],
      channelId: SerializableChannelId.fromJson(json['channelId']),
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'])
          : null,
      uploadDateRaw: json['uploadDateRaw'],
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : null,
      description: json['description'],
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      thumbnails: SerializableThumbnailSet.fromJson(json['thumbnails']),
      keywords: json['keywords'] != null
          ? List<String>.from(json['keywords'])
          : null,
      engagement: SerializableEngagement.fromJson(json['engagement']),
      isLive: json['isLive'],
    );
  }
}

class SerializableVideoId {
  final String value;

  SerializableVideoId(this.value);

  factory SerializableVideoId.fromVideoId(VideoId videoId) {
    return SerializableVideoId(videoId.value);
  }

  VideoId toVideoId() {
    return VideoId(value);
  }

  Map<String, dynamic> toJson() {
    return {'value': value};
  }

  factory SerializableVideoId.fromJson(Map<String, dynamic> json) {
    return SerializableVideoId(json['value']);
  }
}

class SerializableChannelId {
  final String value;

  SerializableChannelId(this.value);

  factory SerializableChannelId.fromChannelId(ChannelId channelId) {
    return SerializableChannelId(channelId.value);
  }

  ChannelId toChannelId() {
    return ChannelId(value);
  }

  Map<String, dynamic> toJson() {
    return {'value': value};
  }

  factory SerializableChannelId.fromJson(Map<String, dynamic> json) {
    return SerializableChannelId(json['value']);
  }
}

class SerializableThumbnailSet {
  final SerializableThumbnail lowRes;
  final SerializableThumbnail mediumRes;
  final SerializableThumbnail highRes;
  final SerializableThumbnail standardRes;
  final SerializableThumbnail maxRes;

  SerializableThumbnailSet({
    required this.lowRes,
    required this.mediumRes,
    required this.highRes,
    required this.standardRes,
    required this.maxRes,
  });

  factory SerializableThumbnailSet.fromThumbnailSet(ThumbnailSet thumbnailSet) {
    return SerializableThumbnailSet(
      lowRes: SerializableThumbnail(
        url: thumbnailSet.lowResUrl,
        width: 0,
        height: 0,
      ),
      mediumRes: SerializableThumbnail(
        url: thumbnailSet.mediumResUrl,
        width: 0,
        height: 0,
      ),
      highRes: SerializableThumbnail(
        url: thumbnailSet.highResUrl,
        width: 0,
        height: 0,
      ),
      standardRes: SerializableThumbnail(
        url: thumbnailSet.standardResUrl,
        width: 0,
        height: 0,
      ),
      maxRes: SerializableThumbnail(
        url: thumbnailSet.maxResUrl,
        width: 0,
        height: 0,
      ),
    );
  }

  ThumbnailSet toThumbnailSet(String videoId) {
    return ThumbnailSet(videoId);
  }

  Map<String, dynamic> toJson() {
    return {
      'lowRes': lowRes.toJson(),
      'mediumRes': mediumRes.toJson(),
      'highRes': highRes.toJson(),
      'standardRes': standardRes.toJson(),
      'maxRes': maxRes.toJson(),
    };
  }

  factory SerializableThumbnailSet.fromJson(Map<String, dynamic> json) {
    return SerializableThumbnailSet(
      lowRes: SerializableThumbnail.fromJson(json['lowRes']),
      mediumRes: SerializableThumbnail.fromJson(json['mediumRes']),
      highRes: SerializableThumbnail.fromJson(json['highRes']),
      standardRes: SerializableThumbnail.fromJson(json['standardRes']),
      maxRes: SerializableThumbnail.fromJson(json['maxRes']),
    );
  }
}

class SerializableThumbnail {
  final String url;
  final int width;
  final int height;

  SerializableThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  factory SerializableThumbnail.fromThumbnail(Thumbnail thumbnail) {
    return SerializableThumbnail(
      url: thumbnail.url.toString(),
      width: thumbnail.width,
      height: thumbnail.height,
    );
  }

  Thumbnail toThumbnail() {
    return Thumbnail(Uri.parse(url), width, height);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'width': width, 'height': height};
  }

  factory SerializableThumbnail.fromJson(Map<String, dynamic> json) {
    return SerializableThumbnail(
      url: json['url'],
      width: json['width'],
      height: json['height'],
    );
  }
}

class SerializableEngagement {
  final int viewCount;
  final int? likeCount;
  final int? dislikeCount;

  SerializableEngagement({
    required this.viewCount,
    this.likeCount,
    this.dislikeCount,
  });

  factory SerializableEngagement.fromEngagement(Engagement engagement) {
    return SerializableEngagement(
      viewCount: engagement.viewCount,
      likeCount: engagement.likeCount,
      dislikeCount: engagement.dislikeCount,
    );
  }

  Engagement toEngagement() {
    return Engagement(viewCount, likeCount, dislikeCount);
  }

  Map<String, dynamic> toJson() {
    return {
      'viewCount': viewCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
    };
  }

  factory SerializableEngagement.fromJson(Map<String, dynamic> json) {
    return SerializableEngagement(
      viewCount: json['viewCount'],
      likeCount: json['likeCount'],
      dislikeCount: json['dislikeCount'],
    );
  }
}
