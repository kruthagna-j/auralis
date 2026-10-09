import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/components/app_snackbar.dart';

class CrashLogService {
  late final Directory _dir;
  final List<String> _channels = ['crash', 'app', 'events', 'network', 'debug'];
  final Map<String, File> _files = {};

  String _logHeader = '';

  final ValueNotifier<bool> loggingActive = ValueNotifier<bool>(false);

  void Function(String?, {int? wrapWidth})? _originalDebugPrint;

  Future<void> init() async {
    _originalDebugPrint = debugPrint;
    _dir = await getApplicationDocumentsDirectory();

    await _generateHeader();

    for (final c in _channels) {
      final f = File(p.join(_dir.path, 'auralis', 'auralis_${c}_logs.txt'));
      if (!await f.exists()) {
        await f.create(recursive: true);
      }
      _files[c] = f;
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, [
    String? context,
  ]) async {
    await _appendToChannel(
      'crash',
      'ERROR',
      '${context == null ? '' : '$context - '}$error\n${stack.toString()}',
    );
  }

  Future<void> log(String channel, String level, String message) async {
    if (!_files.containsKey(channel)) {
      channel = 'app';
    }
    await _appendToChannel(channel, level, message);
  }

  Future<void> _appendToChannel(
    String channel,
    String level,
    String message,
  ) async {
    final ts = DateTime.now().toIso8601String();
    final entry = '---\nTimestamp: $ts\nLevel: $level\nMessage: $message\n\n';
    try {
      final f = _files[channel];
      if (f == null) return;
      await f.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  void startLogging() {
    if (loggingActive.value) return;
    loggingActive.value = true;

    debugPrint = (String? message, {int? wrapWidth}) {
      try {
        _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      } catch (_) {}

      if (message != null) {
        unawaited(log('app', 'DEBUG', message));
      }
    };
  }

  void stopLogging() {
    if (!loggingActive.value) return;
    loggingActive.value = false;
    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
    }
  }

  bool get isLoggingActive => loggingActive.value;

  Future<List<String>> listLogChannels() async {
    return _channels;
  }

  Future<File> getLogFile([String channel = 'crash']) async {
    return _files[channel]!.absolute;
  }

  Future<String> readLog(String channel, {int tail = 5000}) async {
    final f = _files[channel];
    if (f == null || !await f.exists()) return '';
    try {
      final bytes = await f.readAsBytes();
      if (bytes.isEmpty) return '';
      final content = utf8.decode(bytes, allowMalformed: true);
      if (content.length > tail) {
        return '...${content.substring(content.length - tail)}';
      }
      return content;
    } catch (_) {
      return '';
    }
  }

  Future<void> shareLogs(
    BuildContext context, {
    String channel = 'crash',
  }) async {
    final f = _files[channel];
    if (f == null || !await f.exists() || await f.length() == 0) {
      AppSnackBar.showWarning(
        context,
        '${'no_logs_available_for'.tr()} $channel',
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'shared_logs_${channel}.txt'));
    final logsContent = await f.readAsString();
    await tempFile.writeAsString('$_logHeader\n$logsContent');

    await Share.shareXFiles([
      XFile(tempFile.path),
    ], text: 'Auralis — $channel logs');
  }

  Future<void> clearLogs({String? channel}) async {
    try {
      if (channel == null) {
        for (final f in _files.values) {
          await f.writeAsString('');
        }
      } else {
        final f = _files[channel];
        if (f != null) await f.writeAsString('');
      }
    } catch (_) {}
  }

  Future<void> resetAllLogs() async {
    await clearLogs();
  }

  Future<void> _generateHeader() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      String appLine = '${pkg.appName} v${pkg.version} (${pkg.buildNumber})';

      String deviceLine;
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceLine =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}), ${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceLine =
            'iOS ${iosInfo.systemVersion}, ${iosInfo.name} ${iosInfo.model}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        deviceLine =
            'Windows ${winInfo.releaseId} build ${winInfo.buildNumber}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceLine = 'Linux ${linuxInfo.prettyName} (${linuxInfo.id})';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceLine = 'macOS ${macInfo.osRelease}';
      } else {
        deviceLine = 'Unknown platform';
      }

      _logHeader =
          '===== APPLICATION & DEVICE INFO =====\n'
          'App: $appLine\n'
          'Device: $deviceLine\n'
          '=====================================\n\n';
    } catch (_) {
      _logHeader = '';
    }
  }

  void dispose() {
    if (_originalDebugPrint != null) debugPrint = _originalDebugPrint!;
    loggingActive.dispose();
  }
}
