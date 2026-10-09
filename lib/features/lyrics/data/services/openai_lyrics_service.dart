import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import '../../../../features/lyrics/domain/lyrics.dart';
import '../../../../core/providers/settings_provider.dart';

class OpenAiLyricsService {
  Future<LyricsResponse?> getLyrics(
    String artist,
    String title,
    Duration duration,
    SettingsProvider settingsProvider,
  ) async {
    final String? apiKey = settingsProvider.openAiApiKeyValue;
    const String model = 'gpt-5.2';

    final prompt =
        """
You are an expert lyric generator. Your task is to generate the best possible lyrics for the song with the following details:
- Title: "$title"
- Artist: "$artist"
- Duration: ${duration.inSeconds} seconds

The artist might be a YouTube channel name, and the song could be a remix, mashup, or a local track with unconventional naming. The title can contain artist and album/movie names. Generate lyrics that best match the original song, especially if the current track is a remix or mashup.

Your response MUST be a valid JSON object. Do not include any text before or after the JSON object. The JSON object must conform to the following schema:
{
  "type": "object",
  "properties": {
    "synced": {
      "type": "boolean"
    },
    "lyrics": {
      "type": "string"
    }
  },
  "required": ["synced", "lyrics"]
}

- If you generate synchronized (timed) lyrics, set "synced" to true and provide the lyrics in LRC format in the "lyrics" field.
- If you generate plain lyrics, set "synced" to false and provide plain text lyrics in the "lyrics" field.
- If it's not a song or you cannot confidently generate matching lyrics, return a JSON object with "synced": false and "lyrics": "Lyrics not found.".

The lyrics should be in the original language of the song.
""";

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('API Key not set for OpenAI');
      return null;
    }

    const apiUrl = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = {
      "model": model,
      "messages": [
        {"role": "user", "content": prompt},
      ],
      "response_format": {"type": "json_object"},
      "max_tokens": 4000,
    };

    final dio = Dio();

    try {
      final response = await dio.post(
        apiUrl,
        data: body,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String text = data['choices'][0]['message']['content'] as String;

        try {
          final lyricsData = json.decode(text);
          if (lyricsData is Map<String, dynamic> &&
              lyricsData.containsKey('lyrics') &&
              lyricsData.containsKey('synced')) {
            return LyricsResponse(
              lyrics: lyricsData['lyrics'],
              isSynced: lyricsData['synced'],
            );
          }
        } catch (e) {
          return LyricsResponse(lyrics: text, isSynced: false);
        }
      } else {
        debugPrint('Error from OpenAI API: ${response.data}');
        return null;
      }
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return null;
    }

    return null;
  }
}
