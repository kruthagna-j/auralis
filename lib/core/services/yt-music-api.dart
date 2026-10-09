import 'package:dio/dio.dart';

import '../utils/duration_utils.dart';

// Constants
const domain = "https://music.youtube.com/";
const String baseUrl = '${domain}youtubei/v1/';
const fixedParms =
    '?prettyPrint=false&alt=json&key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
const userAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36';

// Headers and Context
final Map<String, String> headers = {
  'user-agent': userAgent,
  'accept': '*/*',
  'accept-encoding': 'gzip, deflate',
  'content-type': 'application/json',
  'content-encoding': 'gzip',
  'origin': domain,
  'cookie': 'CONSENT=YES+1',
};

final Map<String, dynamic> apiContext = {
  'context': {
    'client': {"clientName": "WEB_REMIX", "clientVersion": "1.20230213.01.00"},
    'user': {},
  },
};

final Dio _dio = Dio(BaseOptions(headers: headers));

// API Functions
Future<Response> sendRequest(
  String action,
  Map<dynamic, dynamic> data, {
  additionalParams = "",
}) async {
  try {
    final response = await _dio.post(
      "$baseUrl$action$fixedParms$additionalParams",
      data: data,
    );
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
  } on DioException catch (e) {
    throw Exception('Network error: ${e.message}');
  }
}

Future<Map<String, dynamic>> getSongWithId(String songId) async {
  final data = Map.from(apiContext);
  data['videoId'] = songId;
  final response = (await sendRequest("player", data)).data;

  final category = nav(response, [
    "microformat",
    "microformatDataRenderer",
    "category",
  ]);
  if (category == "Music" ||
      (response["videoDetails"]).containsKey("musicVideoType")) {
    final metadata = parseSongMetadata(response);
    final streamingUrls = parseStreamingUrls(response);
    return {'metadata': metadata, 'streamingUrls': streamingUrls};
  }
  throw Exception('Not a music video');
}

/// Get radio songs (related songs) from a video ID with full metadata
Future<Map<String, dynamic>> getRadioSongs(
  String videoId, {
  int limit = 25,
}) async {
  if (videoId.isNotEmpty && videoId.substring(0, 4) == "MPED") {
    videoId = videoId.substring(4);
  }

  final data = Map.from(apiContext);
  data['enablePersistentPlaylistPanel'] = true;
  data['isAudioOnly'] = true;
  data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';
  data['videoId'] = videoId;
  data['playlistId'] = "RDAMVM$videoId";
  data['params'] = "wAEB"; // Radio parameter

  final List<dynamic> tracks = [];
  dynamic lyricsBrowseId, relatedBrowseId, playlist;
  final Map<String, dynamic> results = {};

  try {
    final response = (await sendRequest("next", data)).data;
    final watchNextRenderer = nav(response, [
      'contents',
      'singleColumnMusicWatchNextResultsRenderer',
      'tabbedRenderer',
      'watchNextTabbedResultsRenderer',
    ]);

    lyricsBrowseId = getTabBrowseId(watchNextRenderer, 1);
    relatedBrowseId = getTabBrowseId(watchNextRenderer, 2);

    results.addAll(
      nav(watchNextRenderer, [
        ...tab_content,
        'musicQueueRenderer',
        'content',
        'playlistPanelRenderer',
      ]),
    );

    if (results['contents'] != null) {
      playlist = results['contents']
          .map(
            (content) => nav(content, [
              'playlistPanelVideoRenderer',
              ...navigation_playlist_id,
            ]),
          )
          .where((e) => e != null)
          .toList()
          .first;
      tracks.addAll(parseWatchPlaylist(results['contents']));
    }

    // Handle continuations to get more radio songs
    dynamic additionalParamsForNext;
    if (results.containsKey('continuations')) {
      requestFunc(additionalParams) async => (await sendRequest(
        "next",
        data,
        additionalParams: additionalParams,
      )).data;
      parseFunc(contents) => parseWatchPlaylist(contents);

      final continuationResults = await getContinuations(
        results,
        'playlistPanelContinuation',
        limit - tracks.length,
        requestFunc,
        parseFunc,
        ctokenPath: 'Radio',
        isAdditionparamReturnReq: true,
      );

      additionalParamsForNext = continuationResults[1];
      tracks.addAll(List<dynamic>.from(continuationResults[0]));
    }

    return {
      'tracks': tracks,
      'playlistId': playlist,
      'lyrics': lyricsBrowseId,
      'related': relatedBrowseId,
      'additionalParamsForNext': additionalParamsForNext,
      'totalTracks': tracks.length,
      'radioId': "RDAMVM$videoId",
    };
  } catch (e) {
    throw Exception('Failed to get radio songs: ${e.toString()}');
  }
}

String? getTabBrowseId(Map<String, dynamic> watchNextRenderer, int tabId) {
  if (!watchNextRenderer['tabs'][tabId]['tabRenderer'].containsKey(
    'unselectable',
  )) {
    return watchNextRenderer['tabs'][tabId]['tabRenderer']['endpoint']['browseEndpoint']['browseId'];
  } else {
    return null;
  }
}

List<dynamic> parseWatchPlaylist(List<dynamic> results) {
  final tracks = [];
  const PPVWR = 'playlistPanelVideoWrapperRenderer';
  const PPVR = 'playlistPanelVideoRenderer';

  for (var result in results) {
    Map<String, dynamic>? counterpart;
    if (result.containsKey(PPVWR)) {
      counterpart =
          result[PPVWR]['counterpart'][0]['counterpartRenderer'][PPVR];
      result = result[PPVWR]['primaryRenderer'];
    }
    if (!result.containsKey(PPVR)) {
      continue;
    }
    final data = result[PPVR];
    if (data.containsKey('unplayableText')) {
      continue;
    }
    final track = parseWatchTrack(data);
    if (counterpart != null) {
      track['counterpart'] = parseWatchTrack(counterpart);
    }
    tracks.add(track);
  }
  return tracks;
}

Map<String, dynamic> parseWatchTrack(Map<String, dynamic> data) {
  final songInfo = parseSongRuns(data['longBylineText']['runs']);

  final track = {
    'videoId': data['videoId'],
    'title': nav(data, title_text),
    'length': nav(data, ['lengthText', 'runs', 0, 'text']),
    'thumbnails': nav(data, thumbnail),
    'videoType': nav(data, ['navigationEndpoint'] + navigation_video_type),
  };

  track.addAll(songInfo);

  // Add duration in seconds if length is available
  if (track['length'] != null) {
    track['duration_seconds'] = DurationUtils.parseDuration(
      track['length'],
    ).inSeconds;
  }

  return track;
}

Future<List> getContinuations(
  Map<String, dynamic> results,
  String continuationType,
  int? limit,
  Function requestFunc,
  Function parseFunc, {
  String ctokenPath = '',
  bool isAdditionparamReturnReq = false,
  String? additionalParams_,
}) async {
  List<dynamic> items = [];
  String? continuationToken;

  if (additionalParams_ != null) {
    // Use provided continuation token
    final Map<String, String> params = {};
    additionalParams_.split('&').forEach((param) {
      final parts = param.split('=');
      if (parts.length == 2) {
        params[parts[0]] = parts[1];
      }
    });
    continuationToken = params['continuation'];
  } else {
    // Extract continuation token from results
    continuationToken = nav(results, [
      'continuations',
      0,
      'nextContinuationData',
      'continuation',
    ]);
  }

  String? additionalParamsForNext;

  while (continuationToken != null && (limit == null || items.length < limit)) {
    try {
      final additionalParams =
          "&ctoken=$continuationToken&continuation=$continuationToken";
      final response = await requestFunc(additionalParams);

      final continuationItems = nav(response, [
        "onResponseReceivedActions",
        0,
        "appendContinuationItemsAction",
        "continuationItems",
      ]);

      if (continuationItems == null || continuationItems.isEmpty) break;

      final contents = parseFunc(continuationItems);
      if (contents.isEmpty) break;

      items.addAll(contents);

      // Get next continuation token
      continuationToken = nav(continuationItems.last, [
        "continuationItemRenderer",
        "continuationEndpoint",
        "continuationCommand",
        "token",
      ]);

      if (isAdditionparamReturnReq && continuationToken != null) {
        additionalParamsForNext =
            "&ctoken=$continuationToken&continuation=$continuationToken";
      }
    } catch (e) {
      break;
    }
  }

  if (isAdditionparamReturnReq) {
    return [items, additionalParamsForNext];
  }
  return items;
}

Map<String, dynamic> parseSongMetadata(Map<String, dynamic> response) {
  final videoDetails = response['videoDetails'];
  return {
    'title': videoDetails['title'],
    'artist': videoDetails['author'],
    'duration': videoDetails['lengthSeconds'],
    'videoId': videoDetails['videoId'],
  };
}

List<Map<String, dynamic>> parseStreamingUrls(Map<String, dynamic> response) {
  final streamingData = response['streamingData'];
  if (streamingData == null || !streamingData.containsKey('formats')) {
    return [];
  }

  final formats = streamingData['formats'] as List;
  return formats.map((format) {
    return {
      'url': format['url'],
      'quality': format['qualityLabel'] ?? format['quality'],
      'format': format['mimeType']?.split(';')[0] ?? 'unknown',
      'bitrate': format['bitrate'],
    };
  }).toList();
}

// Playlist Functions
Future<Map<String, dynamic>> getPlaylistAlbumSongs({
  String? playlistId,
  String? albumId,
  int limit = 3000,
  bool related = false,
  int suggestionsLimit = 0,
}) async {
  String browseId;
  if (playlistId != null) {
    browseId = playlistId.startsWith("VL") ? playlistId : "VL$playlistId";
  } else if (albumId != null) {
    browseId = albumId;
    if (albumId.startsWith("OLAK5uy")) {
      browseId = await getAlbumBrowseId(albumId);
    }
  } else {
    throw Exception("Must provide either playlistId or albumId");
  }
  final data = Map.from(apiContext);
  data['browseId'] = browseId;
  final response = (await sendRequest('browse', data)).data;

  Map<String, dynamic> item;
  if (playlistId != null) {
    // Playlist parsing
    final header =
        nav(response, ['header', "musicDetailHeaderRenderer"]) ??
        nav(response, [
          'contents',
          "twoColumnBrowseResultsRenderer",
          'tabs',
          0,
          "tabRenderer",
          "content",
          "sectionListRenderer",
          "contents",
          0,
          "musicResponsiveHeaderRenderer",
        ]);

    final results =
        nav(response, musicPlaylistShelfRenderer) ??
        nav(response, [
          'contents',
          "singleColumnBrowseResultsRenderer",
          "tabs",
          0,
          "tabRenderer",
          "content",
          'sectionListRenderer',
          'contents',
          0,
          "musicPlaylistShelfRenderer",
        ]);

    item = {'id': results['playlistId']};
    item['title'] = nav(header, title_text);
    item['thumbnails'] =
        nav(header, thumnail_cropped) ??
        nav(header, [
          "thumbnail",
          "musicThumbnailRenderer",
          "thumbnail",
          "thumbnails",
        ]);
    item["description"] = nav(header, description);
    final runCount = header['subtitle']['runs'].length;
    if (runCount > 1) {
      item['author'] = {
        'name': nav(header, subtitle2),
        'id': nav(header, ['subtitle', 'runs', 2] + navigation_browse_id),
      };
      if (runCount == 5) {
        item['year'] = nav(header, subtitle3);
      }
    }

    final secondSubtitleRunCount = header['secondSubtitle']['runs'].length;
    final count =
        (((header['secondSubtitle']['runs'][secondSubtitleRunCount % 3]['text'])
                        .split(' ')[0])
                    .split(',')
                as List)
            .join();
    final songCount = int.parse(count);
    if (header['secondSubtitle']['runs'].length > 1) {
      item['duration'] =
          header['secondSubtitle']['runs'][(secondSubtitleRunCount % 3) +
              2]['text'];
    }
    item['trackCount'] = songCount;

    if (songCount > 0) {
      item['tracks'] = parsePlaylistItems(results['contents']);
      // Add continuation
      final requestFunc = (additionalParams) async =>
          (await sendRequest("browse", {...data, ...additionalParams})).data;
      final parseFunc = (contents) => parsePlaylistItems(contents);
      item['tracks'] = [
        ...(item['tracks']),
        ...(await getContinuationsPlaylist(
          results,
          limit - (item['tracks'] as List).length,
          requestFunc,
          parseFunc,
        )),
      ];
    }
  } else {
    // Album parsing
    item = parseAlbumHeader(response);
    dynamic results =
        nav(response, [
          'contents',
          "twoColumnBrowseResultsRenderer",
          "secondaryContents",
          'sectionListRenderer',
          'contents',
          0,
          'musicShelfRenderer',
        ]) ??
        nav(response, [
          'contents',
          "singleColumnBrowseResultsRenderer",
          "tabs",
          0,
          "tabRenderer",
          "content",
          'sectionListRenderer',
          'contents',
          0,
          'musicShelfRenderer',
        ]);

    item['tracks'] = parsePlaylistItems(
      results['contents'],
      artistsM: item['artists'],
      thumbnailsM: item["thumbnails"],
      albumIdName: {"id": albumId, 'name': item['title']},
      albumYear: item['year'],
      isAlbum: true,
    );
  }

  return {'playlist': item, 'songs': item['tracks'] ?? []};
}

// Additional parsing functions
List<dynamic> parsePlaylistItems(
  List<dynamic> results, {
  List<List<dynamic>>? menuEntries,
  dynamic thumbnailsM,
  dynamic artistsM,
  String? albumYear,
  dynamic albumIdName,
  bool isAlbum = false,
}) {
  List<dynamic> songs = [];
  int count = 1;
  for (dynamic result in results) {
    count += 1;
    if (!result.containsKey('musicResponsiveListItemRenderer')) {
      continue;
    }
    dynamic data = result['musicResponsiveListItemRenderer'];

    String? videoId = nav(data, ['playlistItemData', 'videoId']);

    if (videoId == null && isAlbum) {
      final creditId = nav(data, [
        'menu',
        'menuRenderer',
        'items',
        5,
        'menuNavigationItemRenderer',
        'navigationEndpoint',
        'browseEndpoint',
        'browseId',
      ]);
      videoId = creditId?.split("MPTC")[1];
    }

    if (videoId == null) {
      if (data.containsKey('menu')) {
        for (dynamic item in nav(data, menu_items)) {
          if (item.containsKey('menuServiceItemRenderer')) {
            dynamic menuService = nav(item, menu_service);
            if (menuService.containsKey('playlistEditEndpoint')) {
              videoId =
                  menuService['playlistEditEndpoint']['actions'][0]['removedVideoId'];
            }
          }
        }
      }
    }

    if (videoId == null && nav(data, play_button) != null) {
      if (nav(data, play_button).containsKey('playNavigationEndpoint')) {
        videoId = nav(
          data,
          play_button,
        )['playNavigationEndpoint']['watchEndpoint']['videoId'];
      }
    }

    String? title = getItemText(data, 0);
    if (title == 'Song deleted') {
      continue;
    }

    List? artists = parseSongArtists(data, 1);
    dynamic album = isAlbum ? albumIdName : parseSongAlbum({...data}, 2);
    dynamic duration;
    if (data.containsKey('fixedColumns')) {
      if (getFixedColumnItem(data, 0)!['text'].containsKey('simpleText')) {
        duration = getFixedColumnItem(data, 0)!['text']['simpleText'];
      } else {
        duration = getFixedColumnItem(data, 0)!['text']['runs'][0]['text'];
      }
    }

    dynamic thumbnails_;
    if (data.containsKey('thumbnail')) {
      thumbnails_ = nav(data, thumbnails);
    }

    bool isAvailable = true;
    if (data.containsKey('musicItemRendererDisplayPolicy')) {
      isAvailable =
          data['musicItemRendererDisplayPolicy'] !=
          'MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT';
    }

    String? trackDetails;
    if (isAlbum) {
      trackDetails = data?["index"] != null
          ? "${nav(data, ['index', 'runs', 0, 'text'])}/${results.length}"
          : null;
    }

    dynamic song = {
      'videoId': videoId,
      'title': title,
      'album': album,
      'artists': artists ?? artistsM,
      'thumbnails': isAlbum ? thumbnailsM : thumbnails_ ?? thumbnailsM,
      'isAvailable': isAvailable,
      'trackDetails': trackDetails,
    };

    if (duration != null) {
      song['length'] = duration;
      song['duration_seconds'] = DurationUtils.parseDuration(
        duration,
      ).inSeconds;
    }

    if (menuEntries != null) {
      for (final List<dynamic> menuEntry in menuEntries) {
        song[menuEntry.last] = nav(
          data,
          menu_items + menuEntry.map((e) => e).whereType<String>().toList(),
        );
      }
    }

    if (song['videoId'] != null) {
      songs.add(song);
    }
  }
  return songs;
}

List<dynamic>? parseSongArtists(Map<String, dynamic> data, int index) {
  dynamic flexItem = getFlexColumnItem(data, index);
  if (flexItem == null || flexItem.length == 0) {
    return null;
  } else {
    var runs = flexItem['text']['runs'];
    return parseSongArtistsRuns(runs);
  }
}

List<dynamic> parseSongArtistsRuns(List<dynamic> runs) {
  List<Map<String, dynamic>> artists = [];
  int n = (runs.length / 2).floor() + 1;
  for (var j = 0; j < n; j++) {
    artists.add({
      'name': runs[j * 2]['text'],
      'id': nav(runs[j * 2], navigation_browse_id, noneIfAbsent: false),
    });
  }
  return artists;
}

Map<String, dynamic>? parseSongAlbum(Map<String, dynamic> data, int index) {
  Map<String, dynamic> flexItem = getFlexColumnItem(data, index);
  if (flexItem.isNotEmpty) {
    return {'name': getItemText(data, index), 'id': getBrowseId(flexItem, 0)};
  }
  return null;
}

String? getBrowseId(Map<String, dynamic> item, int index) {
  if (item['text']['runs'][index].containsKey('navigationEndpoint')) {
    return nav(item['text']['runs'][index], navigation_browse_id);
  }
  return null;
}

Map<String, dynamic>? getFixedColumnItem(Map<String, dynamic> item, int index) {
  if (!item['fixedColumns'][index]['musicResponsiveListItemFixedColumnRenderer']['text']
      .containsKey('runs')) {
    return null;
  }
  return item['fixedColumns'][index]['musicResponsiveListItemFixedColumnRenderer'];
}

String? getItemText(
  Map<String, dynamic> item,
  int index, {
  int runIndex = 0,
  bool noneIfAbsent = false,
}) {
  dynamic column = getFlexColumnItem(item, index);
  if (column == null) {
    return noneIfAbsent ? null : "";
  }
  List<dynamic> runs = column['text']['runs'];
  if (noneIfAbsent && runs.length < runIndex + 1) {
    return null;
  }
  return runs[runIndex]['text'];
}

Map<String, dynamic> getFlexColumnItem(Map<String, dynamic> item, int index) {
  if ((item['flexColumns']).length <= index ||
      !item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer']
          .containsKey('text') ||
      !item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer']['text']
          .containsKey('runs')) {
    return {};
  }
  return item['flexColumns'][index]['musicResponsiveListItemFlexColumnRenderer'];
}

// Navigation constants and helper
const title_text = ['title', 'runs', 0, 'text'];
const subtitle2 = ['subtitle', 'runs', 2, 'text'];
const subtitle3 = ['subtitle', 'runs', 4, 'text'];
const description = ['description', 'runs', 0, 'text'];
const thumnail_cropped = [
  'thumbnail',
  'croppedSquareThumbnailRenderer',
  'thumbnail',
  'thumbnails',
];
const navigation_browse_id = [
  'navigationEndpoint',
  'browseEndpoint',
  'browseId',
];
const navigation_playlist_id = [
  'navigationEndpoint',
  'watchEndpoint',
  'playlistId',
];
const navigation_video_type = [
  'watchEndpoint',
  'watchEndpointMusicSupportedConfigs',
  'watchEndpointMusicConfig',
  'musicVideoType',
];
const musicPlaylistShelfRenderer = [
  "contents",
  "twoColumnBrowseResultsRenderer",
  "secondaryContents",
  "sectionListRenderer",
  "contents",
  0,
  "musicPlaylistShelfRenderer",
];
const menu_items = ['menu', 'menuRenderer', 'items'];
const menu_service = ['menuServiceItemRenderer', 'serviceEndpoint'];
const play_button = [
  'overlay',
  'musicItemThumbnailOverlayRenderer',
  'content',
  'musicPlayButtonRenderer',
];
const section_list = ['sectionListRenderer', 'contents'];
const single_column = ['contents', 'singleColumnBrowseResultsRenderer'];
const tab_content = ['tabs', 0, 'tabRenderer', 'content'];
const List<dynamic> single_column_tab = [
  'contents',
  'singleColumnBrowseResultsRenderer',
  'tabs',
  0,
  'tabRenderer',
  'content',
];
const thumbnails = [
  'thumbnail',
  'musicThumbnailRenderer',
  'thumbnail',
  'thumbnails',
];
const thumbnail = ['thumbnail', 'thumbnails'];
const subtitle = ['subtitle', 'runs', 0, 'text'];

Map<String, dynamic> parseSongRuns(List<dynamic> runs) {
  Map<String, dynamic> parsed = {'artists': []};
  for (int i = 0; i < runs.length; i++) {
    Map<String, dynamic> run = runs[i];
    if (i % 2 != 0) {
      // uneven items are always separators
      continue;
    }
    String text = run['text'];
    if (run.containsKey('navigationEndpoint')) {
      // artist or album
      Map<String, dynamic> item = {
        'name': text,
        'id': nav(
          run,
          navigation_browse_id,
          noneIfAbsent: true,
          funName: "parseSongRuns",
        ),
      };
      if (item['id'] != null &&
          (item['id'].startsWith('MPRE') ||
              item['id'].contains("release_detail"))) {
        // album
        parsed['album'] = item;
      } else {
        // artist
        parsed['artists'].add(item);
      }
    } else {
      RegExp regExp = RegExp(r"^\d([^ ])* [^ ]*$");
      if (regExp.hasMatch(text) && i > 0) {
        parsed['views'] = text.split(' ')[0];
      } else if (RegExp(r"^(\d+:)*\d+:\d+$").hasMatch(text)) {
        parsed['length'] = text;
        parsed['duration_seconds'] = DurationUtils.parseDuration(
          text,
        ).inSeconds;
      } else if (RegExp(r"^\d{4}$").hasMatch(text)) {
        parsed['year'] = text;
      } else {
        // artist without id
        parsed['artists'].add({'name': text, 'id': null});
      }
    }
  }
  return parsed;
}

Map<String, dynamic> parseAlbumHeader(Map<String, dynamic> response) {
  Map<String, dynamic> header =
      nav(response, [
        'contents',
        "twoColumnBrowseResultsRenderer",
        'tabs',
        0,
        "tabRenderer",
        "content",
        "sectionListRenderer",
        "contents",
        0,
        "musicResponsiveHeaderRenderer",
      ]) ??
      nav(response, ["header", "musicDetailHeaderRenderer"]);
  Map<String, dynamic> album = {
    'title': nav(header, title_text),
    'type': nav(header, subtitle),
    'thumbnails':
        nav(header, thumnail_cropped) ??
        nav(header, [
          "thumbnail",
          "musicThumbnailRenderer",
          "thumbnail",
          "thumbnails",
        ]),
  };

  album["description"] =
      nav(header, [
        "description",
        "musicDescriptionShelfRenderer",
        "description",
        "runs",
        0,
        "text",
      ]) ??
      (nav(header, [
        "subtitle",
        "runs",
      ])).map((item) => item.values.first).toList().join(" ");

  Map<String, dynamic> albumInfo = parseSongRuns(
    header['subtitle']['runs'].sublist(2),
  );
  try {
    albumInfo.addAll(parseSongRuns(header["straplineTextOne"]['runs']));
  } catch (e) {}
  album.addAll(albumInfo);

  if (header['secondSubtitle']['runs'].length > 1) {
    album['trackCount'] = (header['secondSubtitle']['runs'][0]['text']);
    album['duration'] = header['secondSubtitle']['runs'][2]['text'];
  } else {
    album['duration'] = header['secondSubtitle']['runs'][0]['text'];
  }

  album['audioPlaylistId'] = nav(response, [
    'microformat',
    "microformatDataRenderer",
    "urlCanonical",
  ]).toString().split("list=")[1];

  return album;
}

Future<List> getContinuationsPlaylist(
  Map<String, dynamic> results,
  int? limit,
  Function requestFunc,
  Function parseFunc,
) async {
  List<dynamic> items = [];
  String? continuationToken = nav(results['contents'].last, [
    "continuationItemRenderer",
    "continuationEndpoint",
    "continuationCommand",
    "token",
  ]);

  while (continuationToken != null && (limit == null || items.length < limit)) {
    try {
      final response = await requestFunc({"continuation": continuationToken});
      final continuationItems = nav(response, [
        "onResponseReceivedActions",
        0,
        "appendContinuationItemsAction",
        "continuationItems",
      ]);

      if (continuationItems == null || continuationItems.isEmpty) break;

      final contents = parseFunc(continuationItems);
      if (contents.isEmpty) break;

      items.addAll(contents);
      continuationToken = nav(continuationItems.last, [
        "continuationItemRenderer",
        "continuationEndpoint",
        "continuationCommand",
        "token",
      ]);
    } catch (e) {
      break;
    }
  }
  return items;
}

Future<String> getAlbumBrowseId(String audioPlaylistId) async {
  final response = await _dio.get(
    "${domain}playlist",
    queryParameters: {"list": audioPlaylistId},
  );
  final reg = RegExp(r'\"MPRE.+?\"');
  final matchs = reg.firstMatch(response.data.toString());
  if (matchs != null) {
    final x = (matchs[0])!;
    final res = (x.substring(1)).split("\\")[0];
    return res;
  }
  return audioPlaylistId;
}

// Navigation helper
dynamic nav(
  dynamic root,
  List items, {
  bool noneIfAbsent = false,
  String funName = "d",
}) {
  try {
    dynamic res = root;
    for (final item in items) {
      res = res[item];
    }
    return res;
  } catch (e) {
    return null;
  }
}
