import 'dart:io';
import 'package:flutter/services.dart';

class AudioOutputDevice {
  final String name;
  final String port;
  final int id;
  final int type;

  AudioOutputDevice({
    required this.name,
    required this.port,
    required this.id,
    required this.type,
  });

  factory AudioOutputDevice.fromMap(Map<String, dynamic> map) {
    return AudioOutputDevice(
      name: map['name'] as String? ?? '',
      port: map['port'] as String? ?? 'unknown',
      id: map['id'] as int? ?? 0,
      type: map['type'] as int? ?? 0,
    );
  }
}

class AudioOutputService {
  static const _channel = MethodChannel('com.auralis.app/audio_output');

  static Future<List<AudioOutputDevice>> getAudioDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      final result = await _channel.invokeListMethod<Map>('getAudioDevices');
      if (result == null) return [];
      return result
          .map((e) => AudioOutputDevice.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  static Future<AudioOutputDevice> getCurrentOutput() async {
    if (!Platform.isAndroid) {
      return AudioOutputDevice(
        name: 'Speaker',
        port: 'speaker',
        id: 0,
        type: 0,
      );
    }
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getCurrentOutput',
      );
      if (result == null) {
        return AudioOutputDevice(
          name: 'Speaker',
          port: 'speaker',
          id: 0,
          type: 0,
        );
      }
      return AudioOutputDevice.fromMap(result);
    } on PlatformException {
      return AudioOutputDevice(
        name: 'Speaker',
        port: 'speaker',
        id: 0,
        type: 0,
      );
    }
  }

  static Future<void> openSoundSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openSoundSettings');
    } on PlatformException {}
  }

  static Future<bool> openMediaOutputSwitcher() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'openMediaOutputSwitcher',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> setAudioOutput(int deviceId) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setAudioOutput', {
        'deviceId': deviceId,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
