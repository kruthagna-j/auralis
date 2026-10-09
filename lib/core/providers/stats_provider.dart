import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class SongStats {
  final String id;
  final String title;
  final String artist;
  int totalSeconds;
  int playCount;
  int lastPlayedTimestamp;

  SongStats({
    required this.id,
    required this.title,
    required this.artist,
    this.totalSeconds = 0,
    this.playCount = 0,
    required this.lastPlayedTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'totalSeconds': totalSeconds,
    'playCount': playCount,
    'lastPlayedTimestamp': lastPlayedTimestamp,
  };

  factory SongStats.fromJson(Map<String, dynamic> json) => SongStats(
    id: json['id'] as String,
    title: json['title'] as String,
    artist: json['artist'] as String,
    totalSeconds: json['totalSeconds'] as int,
    playCount: json['playCount'] as int,
    lastPlayedTimestamp: json['lastPlayedTimestamp'] as int,
  );
}

class DailyPlaybackEntry {
  final String dateKey;
  int totalSeconds;
  int playCount;

  DailyPlaybackEntry({
    required this.dateKey,
    this.totalSeconds = 0,
    this.playCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'totalSeconds': totalSeconds,
    'playCount': playCount,
  };

  factory DailyPlaybackEntry.fromJson(Map<String, dynamic> json) =>
      DailyPlaybackEntry(
        dateKey: json['dateKey'] as String,
        totalSeconds: json['totalSeconds'] as int,
        playCount: json['playCount'] as int,
      );
}

class DailyArtistEntry {
  final String dateKey;
  final String artist;
  int totalSeconds;
  int playCount;

  DailyArtistEntry({
    required this.dateKey,
    required this.artist,
    this.totalSeconds = 0,
    this.playCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'artist': artist,
    'totalSeconds': totalSeconds,
    'playCount': playCount,
  };

  factory DailyArtistEntry.fromJson(Map<String, dynamic> json) =>
      DailyArtistEntry(
        dateKey: json['dateKey'] as String,
        artist: json['artist'] as String,
        totalSeconds: json['totalSeconds'] as int,
        playCount: json['playCount'] as int,
      );
}

class StatsProvider with ChangeNotifier {
  static const String _hiveBoxName = 'playback_stats';
  static const String _hiveDailyBoxName = 'playback_stats_daily';
  static const String _hiveDailyArtistBoxName = 'playback_stats_daily_artist';
  static const int _playCountThresholdSeconds = 15;
  static const Duration _saveInterval = Duration(seconds: 10);

  Box<String>? _statsBox;
  Box<String>? _dailyBox;
  Box<String>? _dailyArtistBox;
  Timer? _saveTimer;
  bool _isDirty = false;

  final Map<String, SongStats> _songStats = {};
  final Map<String, int> _artistPlaybackTime = {};
  final Map<String, DailyPlaybackEntry> _dailyStats = {};
  final Map<String, DailyArtistEntry> _dailyArtistStats = {};

  String? _currentPlayingSongId;
  String? _currentTitle;
  String? _currentArtist;
  int? _currentSessionStartTime;
  int? _currentSessionStartPosition;
  int? _lastFlushTime;
  bool _playCountIncrementedThisSession = false;
  bool _isPlaying = false;
  Timer? _periodicUpdateTimer;
  static const Duration _periodicUpdateInterval = Duration(seconds: 10);
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StatsProvider() {
    _initHive();
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _todayKey() => _dateKey(DateTime.now());

  Future<void> _initHive() async {
    _statsBox = await Hive.openBox<String>(_hiveBoxName);
    _dailyBox = await Hive.openBox<String>(_hiveDailyBoxName);
    _dailyArtistBox = await Hive.openBox<String>(_hiveDailyArtistBoxName);
    await _loadStats();
    _startSaveTimer();
  }

  Future<void> _loadStats() async {
    _songStats.clear();
    _artistPlaybackTime.clear();
    _dailyStats.clear();

    for (var key in _statsBox!.keys) {
      final jsonString = _statsBox!.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          final stats = SongStats.fromJson(jsonMap);
          _songStats[stats.id] = stats;
          _updateArtistPlaybackTime(stats.artist, stats.totalSeconds);
        } catch (e) {
          debugPrint('Error decoding song stats from Hive: $e');
        }
      }
    }

    for (var key in _dailyBox!.keys) {
      final jsonString = _dailyBox!.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          final entry = DailyPlaybackEntry.fromJson(jsonMap);
          _dailyStats[entry.dateKey] = entry;
        } catch (e) {
          debugPrint('Error decoding daily stats from Hive: $e');
        }
      }
    }

    for (var key in _dailyArtistBox!.keys) {
      final jsonString = _dailyArtistBox!.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> jsonMap = json.decode(jsonString);
          final entry = DailyArtistEntry.fromJson(jsonMap);
          _dailyArtistStats[key as String] = entry;
        } catch (e) {
          debugPrint('Error decoding daily artist stats from Hive: $e');
        }
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void _updateArtistPlaybackTime(String artist, int seconds) {
    _artistPlaybackTime.update(
      artist,
      (value) => value + seconds,
      ifAbsent: () => seconds,
    );
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(_saveInterval, (timer) {
      if (_isDirty) {
        _saveStats();
        _isDirty = false;
      }
    });
  }

  void recordPlayStart(
    String songId,
    String title,
    String artist,
    int startPositionSeconds,
  ) {
    _currentPlayingSongId = songId;
    _currentTitle = title;
    _currentArtist = artist;
    _currentSessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _currentSessionStartPosition = startPositionSeconds;
    _lastFlushTime = _currentSessionStartTime;
    _playCountIncrementedThisSession = false;
    _isPlaying = true;
    _startPeriodicUpdateTimer();
  }

  void _startPeriodicUpdateTimer() {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = Timer.periodic(_periodicUpdateInterval, (_) {
      _flushCurrentSession();
    });
  }

  void _flushCurrentSession() {
    if (_currentPlayingSongId == null ||
        _lastFlushTime == null ||
        !_isPlaying) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    int delta = (now - _lastFlushTime!) ~/ 1000;
    if (delta <= 0) return;

    final songId = _currentPlayingSongId!;
    final title = _currentTitle ?? 'Unknown Title';
    final artist = _currentArtist ?? 'Unknown Artist';
    bool playCountJustIncremented = false;

    _songStats.update(
      songId,
      (stats) {
        stats.totalSeconds += delta;
        stats.lastPlayedTimestamp = now;
        if (!_playCountIncrementedThisSession) {
          final totalSessionSeconds = (now - _currentSessionStartTime!) ~/ 1000;
          if (totalSessionSeconds >= _playCountThresholdSeconds) {
            stats.playCount++;
            _playCountIncrementedThisSession = true;
            playCountJustIncremented = true;
          }
        }
        return stats;
      },
      ifAbsent: () {
        final totalSessionSeconds = (now - _currentSessionStartTime!) ~/ 1000;
        final shouldCount = totalSessionSeconds >= _playCountThresholdSeconds;
        if (shouldCount) {
          _playCountIncrementedThisSession = true;
          playCountJustIncremented = true;
        }
        return SongStats(
          id: songId,
          title: title,
          artist: artist,
          totalSeconds: delta,
          playCount: shouldCount ? 1 : 0,
          lastPlayedTimestamp: now,
        );
      },
    );

    _artistPlaybackTime.update(
      artist,
      (value) => value + delta,
      ifAbsent: () => delta,
    );
    final todayKey = _todayKey();
    _dailyStats.update(
      todayKey,
      (entry) {
        entry.totalSeconds += delta;
        if (playCountJustIncremented) entry.playCount++;
        return entry;
      },
      ifAbsent: () => DailyPlaybackEntry(
        dateKey: todayKey,
        totalSeconds: delta,
        playCount: playCountJustIncremented ? 1 : 0,
      ),
    );

    final dailyArtistKey = '$todayKey|$artist';
    _dailyArtistStats.update(
      dailyArtistKey,
      (entry) {
        entry.totalSeconds += delta;
        if (playCountJustIncremented) entry.playCount++;
        return entry;
      },
      ifAbsent: () => DailyArtistEntry(
        dateKey: todayKey,
        artist: artist,
        totalSeconds: delta,
        playCount: playCountJustIncremented ? 1 : 0,
      ),
    );

    _lastFlushTime = now;
    _isDirty = true;
    notifyListeners();
  }

  Future<void> recordPlayEnd(
    String? songId,
    String? title,
    String? artist,
    int endPositionSeconds,
  ) async {
    _periodicUpdateTimer?.cancel();
    _periodicUpdateTimer = null;

    if (_currentPlayingSongId != null &&
        _currentSessionStartPosition != null &&
        _currentSessionStartTime != null) {
      _isPlaying = true;
      _flushCurrentSession();

      _currentPlayingSongId = null;
      _currentTitle = null;
      _currentArtist = null;
      _currentSessionStartTime = null;
      _currentSessionStartPosition = null;
      _lastFlushTime = null;
      _isPlaying = false;
      _playCountIncrementedThisSession = false;
    }
  }

  Future<void> _saveStats() async {
    if (_statsBox == null || !_statsBox!.isOpen) {
      _statsBox = await Hive.openBox<String>(_hiveBoxName);
    }
    if (_dailyBox == null || !_dailyBox!.isOpen) {
      _dailyBox = await Hive.openBox<String>(_hiveDailyBoxName);
    }

    final Map<String, String> updates = {};
    for (var entry in _songStats.entries) {
      updates[entry.key] = json.encode(entry.value.toJson());
    }
    await _statsBox!.putAll(updates);

    final Map<String, String> dailyUpdates = {};
    for (var entry in _dailyStats.entries) {
      dailyUpdates[entry.key] = json.encode(entry.value.toJson());
    }
    await _dailyBox!.putAll(dailyUpdates);

    if (_dailyArtistBox == null || !_dailyArtistBox!.isOpen) {
      _dailyArtistBox = await Hive.openBox<String>(_hiveDailyArtistBoxName);
    }
    final Map<String, String> dailyArtistUpdates = {};
    for (var entry in _dailyArtistStats.entries) {
      dailyArtistUpdates[entry.key] = json.encode(entry.value.toJson());
    }
    await _dailyArtistBox!.putAll(dailyArtistUpdates);

    debugPrint('Playback stats saved to Hive.');
  }

  Future<void> clearAllStats() async {
    _songStats.clear();
    _artistPlaybackTime.clear();
    _dailyStats.clear();
    _dailyArtistStats.clear();
    _currentPlayingSongId = null;
    _currentTitle = null;
    _currentArtist = null;
    _currentSessionStartTime = null;
    _currentSessionStartPosition = null;
    _lastFlushTime = null;
    _playCountIncrementedThisSession = false;
    _isPlaying = false;
    _isDirty = false;

    if (_statsBox == null || !_statsBox!.isOpen) {
      _statsBox = await Hive.openBox<String>(_hiveBoxName);
    }
    if (_dailyBox == null || !_dailyBox!.isOpen) {
      _dailyBox = await Hive.openBox<String>(_hiveDailyBoxName);
    }
    if (_dailyArtistBox == null || !_dailyArtistBox!.isOpen) {
      _dailyArtistBox = await Hive.openBox<String>(_hiveDailyArtistBoxName);
    }

    await _statsBox!.clear();
    await _dailyBox!.clear();
    await _dailyArtistBox!.clear();

    notifyListeners();
  }

  int get totalSongsPlayed => _songStats.length;
  int get _currentSessionElapsed {
    if (_isPlaying && _currentPlayingSongId != null && _lastFlushTime != null) {
      final elapsed =
          (DateTime.now().millisecondsSinceEpoch - _lastFlushTime!) ~/ 1000;
      return elapsed > 0 ? elapsed : 0;
    }
    return 0;
  }

  Duration get totalPlaybackTime {
    int totalSeconds = 0;
    for (final stats in _songStats.values) {
      totalSeconds += stats.totalSeconds;
    }
    totalSeconds += _currentSessionElapsed;
    return Duration(seconds: totalSeconds);
  }

  Map<String, Duration> get mostPlayedArtists {
    final playbackTime = Map<String, int>.from(_artistPlaybackTime);
    if (_isPlaying &&
        _currentPlayingSongId != null &&
        _currentSessionStartTime != null) {
      final stats = _songStats[_currentPlayingSongId];
      if (stats != null) {
        playbackTime.update(
          stats.artist,
          (value) => value + _currentSessionElapsed,
          ifAbsent: () => _currentSessionElapsed,
        );
      }
    }
    var sortedArtists = Map.fromEntries(
      playbackTime.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sortedArtists.map(
      (key, value) => MapEntry(key, Duration(seconds: value)),
    );
  }

  List<DailyPlaybackEntry> getDailyStats({int days = 7}) {
    final now = DateTime.now();
    final List<DailyPlaybackEntry> result = [];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);
      result.add(
        _dailyStats[key] ??
            DailyPlaybackEntry(dateKey: key, totalSeconds: 0, playCount: 0),
      );
    }
    if (result.isNotEmpty && _currentSessionElapsed > 0) {
      final todayEntry = result.last;
      result[result.length - 1] = DailyPlaybackEntry(
        dateKey: todayEntry.dateKey,
        totalSeconds: todayEntry.totalSeconds + _currentSessionElapsed,
        playCount: todayEntry.playCount,
      );
    }
    return result;
  }

  List<DailyPlaybackEntry> getWeeklyStats({int weeks = 4}) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final List<DailyPlaybackEntry> result = [];

    for (int w = weeks - 1; w >= 0; w--) {
      final weekStart = currentWeekStart.subtract(Duration(days: w * 7));
      int totalSeconds = 0;
      int playCount = 0;
      for (int d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        final key = _dateKey(date);
        final entry = _dailyStats[key];
        if (entry != null) {
          totalSeconds += entry.totalSeconds;
          playCount += entry.playCount;
        }
      }
      if (w == 0) {
        totalSeconds += _currentSessionElapsed;
      }
      result.add(
        DailyPlaybackEntry(
          dateKey: _dateKey(weekStart),
          totalSeconds: totalSeconds,
          playCount: playCount,
        ),
      );
    }
    return result;
  }

  List<DailyPlaybackEntry> getMonthlyStats({int months = 6}) {
    final now = DateTime.now();
    final List<DailyPlaybackEntry> result = [];

    for (int m = months - 1; m >= 0; m--) {
      int year = now.year;
      int month = now.month - m;
      while (month <= 0) {
        month += 12;
        year--;
      }
      final daysInMonth = DateTime(year, month + 1, 0).day;
      int totalSeconds = 0;
      int playCount = 0;
      for (int d = 1; d <= daysInMonth; d++) {
        final key = _dateKey(DateTime(year, month, d));
        final entry = _dailyStats[key];
        if (entry != null) {
          totalSeconds += entry.totalSeconds;
          playCount += entry.playCount;
        }
      }
      if (m == 0) {
        totalSeconds += _currentSessionElapsed;
      }
      final monthKey = _dateKey(DateTime(year, month, 1));
      result.add(
        DailyPlaybackEntry(
          dateKey: monthKey,
          totalSeconds: totalSeconds,
          playCount: playCount,
        ),
      );
    }
    return result;
  }

  Duration get todayPlaybackTime {
    final today = getDailyStats(days: 1);
    return Duration(seconds: today.first.totalSeconds);
  }

  Duration get thisWeekPlaybackTime {
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    final daily = getDailyStats(days: daysSinceMonday + 1);
    int total = 0;
    for (final d in daily) {
      total += d.totalSeconds;
    }
    return Duration(seconds: total);
  }

  Duration get thisMonthPlaybackTime {
    final monthly = getMonthlyStats(months: 1);
    return Duration(seconds: monthly.first.totalSeconds);
  }

  Set<String> _dateKeysForLastDays(int days) {
    final now = DateTime.now();
    return Set.from(
      List.generate(days, (i) => _dateKey(now.subtract(Duration(days: i)))),
    );
  }

  Set<String> _dateKeysForThisWeek() {
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    return _dateKeysForLastDays(daysSinceMonday + 1);
  }

  Set<String> _dateKeysForThisMonth() {
    final now = DateTime.now();
    return Set.from(
      List.generate(
        now.day,
        (i) => _dateKey(DateTime(now.year, now.month, i + 1)),
      ),
    );
  }

  Set<String> _dateKeysForWeeks(int weeks) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final startDate = currentWeekStart.subtract(
      Duration(days: (weeks - 1) * 7),
    );
    final totalDays = now.difference(startDate).inDays + 1;
    return Set.from(
      List.generate(
        totalDays,
        (i) => _dateKey(startDate.add(Duration(days: i))),
      ),
    );
  }

  Set<String> _dateKeysForMonths(int months) {
    final now = DateTime.now();
    final Set<String> keys = {};
    for (int m = months - 1; m >= 0; m--) {
      int year = now.year;
      int month = now.month - m;
      while (month <= 0) {
        month += 12;
        year--;
      }
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        keys.add(_dateKey(DateTime(year, month, d)));
      }
    }
    return keys;
  }

  Map<String, Duration> getArtistPlaybackForDates(Set<String> dateKeys) {
    final Map<String, int> artistSeconds = {};
    for (final entry in _dailyArtistStats.entries) {
      final pipeIndex = entry.key.indexOf('|');
      if (pipeIndex > 0) {
        final dateKey = entry.key.substring(0, pipeIndex);
        if (dateKeys.contains(dateKey)) {
          final artist = entry.value.artist;
          artistSeconds.update(
            artist,
            (v) => v + entry.value.totalSeconds,
            ifAbsent: () => entry.value.totalSeconds,
          );
        }
      }
    }
    if (_isPlaying && _currentArtist != null && _currentPlayingSongId != null) {
      final todayKey = _todayKey();
      if (dateKeys.contains(todayKey)) {
        artistSeconds.update(
          _currentArtist!,
          (v) => v + _currentSessionElapsed,
          ifAbsent: () => _currentSessionElapsed,
        );
      }
    }
    final sorted = Map.fromEntries(
      artistSeconds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted.map((k, v) => MapEntry(k, Duration(seconds: v)));
  }

  Map<String, int> getArtistSongCountForDates(Set<String> dateKeys) {
    final Map<String, int> artistCounts = {};
    for (final entry in _dailyArtistStats.entries) {
      final pipeIndex = entry.key.indexOf('|');
      if (pipeIndex > 0) {
        final dateKey = entry.key.substring(0, pipeIndex);
        if (dateKeys.contains(dateKey)) {
          final artist = entry.value.artist;
          artistCounts.update(
            artist,
            (v) => v + entry.value.playCount,
            ifAbsent: () => entry.value.playCount,
          );
        }
      }
    }
    final sorted = Map.fromEntries(
      artistCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return sorted;
  }

  int getSongsPlayedForDates(Set<String> dateKeys) {
    int total = 0;
    for (final key in dateKeys) {
      total += _dailyStats[key]?.playCount ?? 0;
    }
    return total;
  }

  int get todaySongsPlayed => getSongsPlayedForDates({_todayKey()});
  Map<String, Duration> get dailyArtists =>
      getArtistPlaybackForDates(_dateKeysForLastDays(7));
  Map<String, int> get dailyArtistSongCounts =>
      getArtistSongCountForDates(_dateKeysForLastDays(7));

  int get thisWeekSongsPlayed => getSongsPlayedForDates(_dateKeysForThisWeek());
  Map<String, Duration> get weeklyArtists =>
      getArtistPlaybackForDates(_dateKeysForWeeks(4));
  Map<String, int> get weeklyArtistSongCounts =>
      getArtistSongCountForDates(_dateKeysForWeeks(4));

  int get thisMonthSongsPlayed =>
      getSongsPlayedForDates(_dateKeysForThisMonth());
  Map<String, Duration> get monthlyArtists =>
      getArtistPlaybackForDates(_dateKeysForMonths(6));
  Map<String, int> get monthlyArtistSongCounts =>
      getArtistSongCountForDates(_dateKeysForMonths(6));

  int getSongsPlayedForWeeks(int weeks) =>
      getSongsPlayedForDates(_dateKeysForWeeks(weeks));

  int getSongsPlayedForMonths(int months) =>
      getSongsPlayedForDates(_dateKeysForMonths(months));

  @override
  void dispose() {
    _periodicUpdateTimer?.cancel();
    _saveTimer?.cancel();
    if (_currentPlayingSongId != null && _isPlaying) {
      _flushCurrentSession();
    }
    _isPlaying = false;
    if (_isDirty) {
      _saveStats();
    }
    _statsBox?.close();
    _dailyBox?.close();
    _dailyArtistBox?.close();
    super.dispose();
  }
}
