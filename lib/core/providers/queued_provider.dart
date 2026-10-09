import 'package:flutter/foundation.dart';

import '../services/queue_storage_service.dart';
import '../models/song_model.dart';
import '../services/player_service.dart';

enum RepeatMode { off, all, one }

class QueueProvider with ChangeNotifier {
  List<SongInfo> _queue = [];
  int _currentIndex = 0;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<int> _shuffleIndices = [];
  String? _playlistId;
  String? _playlistName;
  PlayerService? _playerService;

  List<SongInfo> get queue => _queue;
  int get currentIndex => _currentIndex;
  String? get playlistId => _playlistId;
  String? get playlistName => _playlistName;
  bool get hasLocalSongsInQueue =>
      _playlistId == 'local_music' && _queue.isNotEmpty;
  bool get hasNext {
    if (_repeatMode != RepeatMode.off) return true;
    if (_isShuffleEnabled) {
      final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      return currentShuffleIndex < _shuffleIndices.length - 1;
    }
    return _currentIndex < _queue.length - 1;
  }

  bool get hasPrevious {
    if (_repeatMode != RepeatMode.off) return true;
    if (_isShuffleEnabled) {
      final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      return currentShuffleIndex > 0;
    }
    return _currentIndex > 0;
  }

  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _repeatMode != RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;
  int get queueLength => _queue.length;
  SongInfo? get currentVideo =>
      _queue.isNotEmpty ? _queue[_currentIndex] : null;

  SongInfo? peekNext() {
    if (_queue.isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      return _queue[_currentIndex];
    }

    if (_isShuffleEnabled) {
      if (_shuffleIndices.isEmpty) return null;
      final currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      if (currentShuffleIndex == -1) return null;
      if (currentShuffleIndex < _shuffleIndices.length - 1) {
        return _queue[_shuffleIndices[currentShuffleIndex + 1]];
      } else if (_repeatMode == RepeatMode.all) {
        return _queue[_shuffleIndices[0]];
      } else {
        return null;
      }
    } else {
      if (_currentIndex < _queue.length - 1) {
        return _queue[_currentIndex + 1];
      } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
        return _queue[0];
      } else {
        return null;
      }
    }
  }

  bool _isDuplicate(SongInfo song) {
    return _queue.any((item) => item.videoId == song.videoId);
  }

  void setPlayerService(PlayerService playerService) {
    _playerService = playerService;
    loadQueue();
  }

  void addToQueue(SongInfo song) {
    if (!_isDuplicate(song)) {
      _queue.add(song);
      if (_isShuffleEnabled) _updateShuffleIndices();
      notifyListeners();
      saveQueue();
    }
  }

  Future<void> loadQueue() async {
    final data = await QueueStorage.loadQueue();
    if (data != null) {
      _queue = (data['queue'] as List)
          .map((json) => QueueStorage.mapToSong(json))
          .toList();
      _currentIndex = data['currentIndex'] ?? 0;
      _isShuffleEnabled = data['isShuffle'] ?? false;
      final repeatStr =
          data['repeatMode'] as String? ??
          (data['isRepeat'] == true ? 'all' : 'off');
      _repeatMode = RepeatMode.values.firstWhere(
        (m) => m.name == repeatStr,
        orElse: () => RepeatMode.off,
      );
      _shuffleIndices = (data['shuffleIndices'] as List?)?.cast<int>() ?? [];
      _playlistId = data['playlistId'];
      _playlistName = data['playlistName'];

      if (_playerService != null) {
        _updatePlayerServiceShuffleMode();
        _updatePlayerServiceLoopMode();
      }

      notifyListeners();
    }
  }

  Future<void> saveQueue() async {
    await QueueStorage.saveQueue(
      _queue,
      _currentIndex,
      _isShuffleEnabled,
      _repeatMode.name,
      _shuffleIndices,
      _playlistId,
      _playlistName,
    );
  }

  void addToQueueNext(SongInfo song) {
    int existingIndex = _queue.indexWhere((s) => s.videoId == song.videoId);

    if (existingIndex != -1) {
      if (existingIndex == _currentIndex) {
        return;
      }
      _queue.removeAt(existingIndex);
      if (existingIndex < _currentIndex) {
        _currentIndex--;
      }
    }
    _queue.insert(_currentIndex + 1, song);

    if (_isShuffleEnabled) _updateShuffleIndices();
    notifyListeners();
    saveQueue();
    _playerService?.insertSongIntoPlaylist(_currentIndex + 1, song);
  }

  void addAllToQueue(List<SongInfo> songs) {
    final uniqueSongs = songs.where((song) => !_isDuplicate(song)).toList();
    if (uniqueSongs.isNotEmpty) {
      _queue.addAll(uniqueSongs);
      if (_isShuffleEnabled) _updateShuffleIndices();
      notifyListeners();
      saveQueue();
    }
  }

  void removeFromQueue(int index) {
    if (index < _currentIndex) _currentIndex--;
    _queue.removeAt(index);
    if (_isShuffleEnabled) _updateShuffleIndices();
    notifyListeners();
    saveQueue();
    _playerService?.removeFromPlaylist(index);
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = 0;
    _shuffleIndices.clear();
    _playlistId = null;
    notifyListeners();
    saveQueue();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (_currentIndex < oldIndex && _currentIndex >= newIndex) {
      _currentIndex++;
    } else if (_currentIndex > oldIndex && _currentIndex <= newIndex) {
      _currentIndex--;
    }

    if (_isShuffleEnabled) _updateShuffleIndices();
    notifyListeners();
    saveQueue();
    _playerService?.moveSongInPlaylist(oldIndex, newIndex);
  }

  SongInfo? getNextSong() {
    if (_queue.isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      return _queue[_currentIndex];
    }

    int nextIndex;
    if (_isShuffleEnabled) {
      int currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      if (currentShuffleIndex < _shuffleIndices.length - 1) {
        nextIndex = _shuffleIndices[currentShuffleIndex + 1];
      } else if (_repeatMode == RepeatMode.all) {
        nextIndex = _shuffleIndices[0];
      } else {
        return null;
      }
    } else {
      if (_currentIndex < _queue.length - 1) {
        nextIndex = _currentIndex + 1;
      } else if (_repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return null;
      }
    }

    if (nextIndex >= 0 && nextIndex < _queue.length) {
      _currentIndex = nextIndex;
      notifyListeners();
      saveQueue();
      return _queue[_currentIndex];
    }

    return null;
  }

  SongInfo? getPreviousSong() {
    if (_queue.isEmpty) return null;

    if (_repeatMode == RepeatMode.one) {
      return _queue[_currentIndex];
    }

    if (!hasPrevious && _repeatMode == RepeatMode.off) return null;

    if (_isShuffleEnabled) {
      int currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      if (currentShuffleIndex > 0) {
        _currentIndex = _shuffleIndices[currentShuffleIndex - 1];
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _shuffleIndices.last;
      } else {
        return null;
      }
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_repeatMode == RepeatMode.all) {
        _currentIndex = _queue.length - 1;
      } else {
        return null;
      }
    }

    notifyListeners();
    saveQueue();
    return _queue[_currentIndex];
  }

  void updateSongInQueue(int index, SongInfo updatedSong) {
    if (index >= 0 && index < _queue.length) {
      _queue[index] = updatedSong;
      notifyListeners();
      saveQueue();
    }
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length && _currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
      saveQueue();
    }
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled) {
      _updateShuffleIndices();
    }
    notifyListeners();
    saveQueue();

    _updatePlayerServiceShuffleMode();
  }

  void setRepeatMode(RepeatMode mode) {
    if (_repeatMode == mode) return;
    _repeatMode = mode;
    notifyListeners();
    saveQueue();
    _updatePlayerServiceLoopMode();
  }

  void toggleRepeat() {
    _repeatMode = switch (_repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    notifyListeners();
    saveQueue();
    _updatePlayerServiceLoopMode();
  }

  void _updatePlayerServiceShuffleMode() {
    _playerService?.setShuffleMode(_isShuffleEnabled);
  }

  void _updatePlayerServiceLoopMode() {
    _playerService?.setLoopMode(_repeatMode);
  }

  void _updateShuffleIndices() {
    _shuffleIndices = List.generate(_queue.length, (index) => index)..shuffle();
    if (_currentIndex != -1) {
      int currentShuffleIndex = _shuffleIndices.indexOf(_currentIndex);
      if (currentShuffleIndex != -1) {
        _shuffleIndices.remove(_currentIndex);
        _shuffleIndices.insert(0, _currentIndex);
      }
    }
  }

  void setPlaylistId(String? playlistId) {
    _playlistId = playlistId;
    notifyListeners();
  }

  void setPlaylistName(String? playlistName) {
    _playlistName = playlistName;
    notifyListeners();
    saveQueue();
  }

  void setQueue(
    List<SongInfo> songs, {
    int currentIndex = 0,
    String? playlistId,
    String? playlistName,
  }) {
    _queue = List<SongInfo>.from(songs);
    _playlistId = playlistId;
    _playlistName = playlistName;

    if (_isShuffleEnabled) {
      _updateShuffleIndices();
    } else {
      _shuffleIndices = [];
    }

    if (_queue.isEmpty) {
      _currentIndex = 0;
    } else {
      if (currentIndex < 0) currentIndex = 0;
      if (currentIndex >= _queue.length) currentIndex = _queue.length - 1;
      _currentIndex = currentIndex;
    }

    notifyListeners();
    saveQueue();
  }
}
