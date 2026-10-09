import 'package:dio/dio.dart';
import '../../../../features/lyrics/domain/lyrics.dart';

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';

  Future<LyricsResponse?> searchLyrics(String artist, String title) async {
    final queryParams = {'artist_name': artist, 'track_name': title};

    final uri = Uri.parse(
      '$_baseUrl/get',
    ).replace(queryParameters: queryParams);

    final dio = Dio();
    final response = await dio.get(
      uri.toString(),
      options: Options(
        headers: {'Accept': 'application/json', 'Accept-Charset': 'utf-8'},
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null) {
        if (data['syncedLyrics'] != null) {
          return LyricsResponse(lyrics: data['syncedLyrics'], isSynced: true);
        } else if (data['plainLyrics'] != null) {
          return LyricsResponse(lyrics: data['plainLyrics'], isSynced: false);
        }
      }
    }
    return null;
  }
}
