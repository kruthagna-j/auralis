import 'dart:convert';

import 'package:hive_ce/hive.dart';

import '../../../../../core/services/settings_storage_service.dart';
import '../../../../../core/services/media_kit_player_adapter.dart';

class EqualizerBandDescriptor {
  final int index;
  final double centerFrequency;
  final double gain;

  const EqualizerBandDescriptor({
    required this.index,
    required this.centerFrequency,
    required this.gain,
  });

  EqualizerBandDescriptor copyWith({double? gain}) {
    return EqualizerBandDescriptor(
      index: index,
      centerFrequency: centerFrequency,
      gain: gain ?? this.gain,
    );
  }
}

class EqualizerParameters {
  final double minDecibels;
  final double maxDecibels;
  final List<EqualizerBandDescriptor> bands;

  const EqualizerParameters({
    required this.minDecibels,
    required this.maxDecibels,
    required this.bands,
  });
}

class EqualizerService {
  static const String _equalizerEnabledKey = 'equalizer_enabled';
  static const String _currentPresetKey = 'current_preset';
  static const String _bandGainsKey = 'band_gains';
  static const String _customPresetsKey = 'custom_presets';

  static const Map<String, List<double>> builtInPresets = {
    'Auralis': [5.5, 3.0, 0.5, 0.0, 0.0, 0.8],
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Rock': [4.0, 3.0, -2.0, 1.5, 3.0, 4.0],
    'Pop': [3.5, 2.0, 1.0, 1.0, 2.0, 3.5],
    'Jazz': [2.5, 2.0, 1.0, 0.5, 1.5, 2.5],
    'Classical': [2.0, 1.5, 0.5, -0.5, 1.0, 1.8],
    'Bass Boost': [8.0, 5.0, 2.0, -1.0, -2.0, -2.5],
    'Vocal Boost': [-2.0, -1.0, 2.5, 4.0, 3.5, 2.0],
    'Dance': [6.0, 4.0, 0.0, 2.5, 4.0, 5.0],
    'Hip-Hop': [7.0, 5.5, 1.0, -1.0, 1.5, 2.0],
    'Acoustic': [1.5, 2.0, 2.5, 2.0, 1.5, 1.0],
    'Treble Boost': [-3.0, -2.0, 0.5, 3.5, 5.5, 6.5],
  };

  static const List<double> _bandFrequencies = [
    60,
    230,
    910,
    3600,
    14000,
    16000,
  ];

  bool _equalizerEnabled = false;
  String _currentPreset = 'Auralis';
  Map<String, List<double>> _customPresets = {};
  List<double> _gains = [0, 0, 0, 0, 0, 0];
  MediaKitPlayerAdapter? _playerAdapter;
  late final Future<void> _initFuture;

  EqualizerService() {
    _initFuture = _loadSettings();
  }

  Future<Box<dynamic>> _settingsBox() => SettingsStorageService.getBox();

  Future<void> _loadSettings() async {
    final box = await _settingsBox();
    _equalizerEnabled = (box.get(_equalizerEnabledKey) as bool?) ?? false;

    final customPresetsString = box.get(_customPresetsKey) as String?;
    if (customPresetsString != null) {
      try {
        final decoded = jsonDecode(customPresetsString) as Map<String, dynamic>;
        _customPresets = decoded.map((key, value) {
          final list = (value as List)
              .map((e) => (e as num).toDouble())
              .toList();
          return MapEntry(key, list);
        });
      } catch (_) {
        _customPresets = {};
      }
    }

    _currentPreset = (box.get(_currentPresetKey) as String?) ?? 'Auralis';
    final bandGainsString = box.get(_bandGainsKey) as String?;
    if (bandGainsString != null) {
      _gains = bandGainsString
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => double.tryParse(e) ?? 0.0)
          .toList();
    } else {
      _gains = List<double>.from(builtInPresets[_currentPreset] ?? _gains);
    }

    while (_gains.length < _bandFrequencies.length) {
      _gains.add(0.0);
    }
  }

  Future<void> _saveSettings() async {
    final box = await _settingsBox();
    await box.put(_bandGainsKey, _gains.join(','));
    await box.put(_customPresetsKey, jsonEncode(_customPresets));
    await box.put(_currentPresetKey, _currentPreset);
    await box.put(_equalizerEnabledKey, _equalizerEnabled);
  }

  Future<void> bindPlayer(MediaKitPlayerAdapter adapter) async {
    await _initFuture;
    _playerAdapter = adapter;
    await applyToBoundPlayer();
  }

  Future<void> applyToBoundPlayer() async {
    if (_playerAdapter == null) return;
    final graph = _equalizerEnabled ? buildFilterGraph() : '';
    try {
      await _playerAdapter!.setAudioFilterGraph(graph);
    } catch (_) {}
  }

  String buildFilterGraph() {
    final filters = <String>[];
    for (int i = 0; i < _bandFrequencies.length; i++) {
      final frequency = _bandFrequencies[i];
      final gain = _gains[i].toStringAsFixed(1);
      filters.add('equalizer=f=$frequency:t=q:w=1:g=$gain');
    }

    return filters.join(',');
  }

  bool get equalizerEnabled => _equalizerEnabled;
  String get currentPreset => _currentPreset;

  Future<EqualizerParameters> getEqualizerParameters() async {
    return EqualizerParameters(
      minDecibels: -12.0,
      maxDecibels: 12.0,
      bands: List.generate(_bandFrequencies.length, (i) {
        return EqualizerBandDescriptor(
          index: i,
          centerFrequency: _bandFrequencies[i],
          gain: _gains[i],
        );
      }),
    );
  }

  Future<void> setEqualizerEnabled(bool enabled) async {
    _equalizerEnabled = enabled;
    await _saveSettings();
    await applyToBoundPlayer();
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _gains.length) return;
    _gains[bandIndex] = gain.clamp(-12.0, 12.0);
    await _saveSettings();
    await applyToBoundPlayer();
  }

  Future<void> applyPreset(String presetName) async {
    List<double>? gains;
    if (builtInPresets.containsKey(presetName)) {
      gains = builtInPresets[presetName];
    } else if (_customPresets.containsKey(presetName)) {
      gains = _customPresets[presetName];
    }

    if (gains != null) {
      _gains = List<double>.from(gains);
      while (_gains.length < _bandFrequencies.length) {
        _gains.add(0.0);
      }
      _currentPreset = presetName;
      await _saveSettings();
      await applyToBoundPlayer();
    }
  }

  Future<Map<String, List<double>>> getAllPresets() async {
    return {...builtInPresets, ..._customPresets};
  }

  Future<void> saveCustomPreset(String name, List<double> gains) async {
    _customPresets[name] = List<double>.from(gains);
    await _saveSettings();
  }

  Future<bool> renameCustomPreset(String oldName, String newName) async {
    if (!_customPresets.containsKey(oldName)) return false;
    if (_customPresets.containsKey(newName) ||
        builtInPresets.containsKey(newName)) {
      return false;
    }
    final gains = _customPresets.remove(oldName)!;
    _customPresets[newName] = gains;

    if (_currentPreset == oldName) {
      _currentPreset = newName;
    }
    await _saveSettings();
    return true;
  }

  static String getFrequencyText(double frequency) {
    if (frequency >= 1000) {
      return '${(frequency / 1000).toStringAsFixed(1)}kHz';
    }
    return '${frequency.round()}Hz';
  }
}
