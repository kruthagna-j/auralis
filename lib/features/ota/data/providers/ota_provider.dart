import 'dart:convert';
import 'dart:io';

import 'package:android_package_installer/android_package_installer.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/ota_model.dart';

class OTAProvider with ChangeNotifier {
  static const String _baseUpdateUrl =
      'https://raw.githubusercontent.com/kruthagna-j/auralis-app/refs/heads/main/docs';
  static const String _lastCheckedKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';

  final Dio _dio = Dio();
  String _updateChannel = 'stable';

  OTAStatus _status = OTAStatus.idle;
  OTAUpdateInfo? _updateInfo;
  OTADownloadProgress? _downloadProgress;
  OTAError? _error;
  String? _errorMessage;
  String? _downloadedFilePath;
  CancelToken? _cancelToken;
  bool _isUpdateUIShown = false;
  bool _isOTAScreenActive = false;

  OTAStatus get status => _status;
  OTAUpdateInfo? get updateInfo => _updateInfo;
  OTADownloadProgress? get downloadProgress => _downloadProgress;
  OTAError? get error => _error;
  String? get errorMessage => _errorMessage;
  bool get hasUpdate =>
      _status == OTAStatus.updateAvailable ||
      _status == OTAStatus.downloaded ||
      _status == OTAStatus.downloading;
  bool get isUpdateUIShown => _isUpdateUIShown;
  bool get isOTAScreenActive => _isOTAScreenActive;

  OTAProvider() {
    _initializeDio();
  }

  void _initializeDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'User-Agent': 'Auralis-Music-App'},
    );
  }

  Future<void> checkForUpdates({
    bool showNoUpdateMessage = false,
    bool showChecking = true,
  }) async {
    if (_status == OTAStatus.checking) return;

    if (Platform.isLinux) {
      _setStatus(OTAStatus.idle);
      return;
    }

    if (showChecking) {
      _setStatus(OTAStatus.checking);
    }
    _error = null;
    _errorMessage = null;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;

      final platform = Platform.isAndroid
          ? 'android'
          : Platform.isWindows
          ? 'windows'
          : 'linux';
      final updateUrl = '$_baseUpdateUrl/$platform-update-$_updateChannel.json';

      final response = await _dio.get(updateUrl);
      final data = response.data is String
          ? json.decode(response.data)
          : response.data;

      String? deviceAbi;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final abis = androidInfo.supportedAbis;
        deviceAbi = abis.isNotEmpty ? abis.first : 'arm64-v8a';
      }

      final updateInfo = OTAUpdateInfo.fromJson(data, deviceAbi: deviceAbi);

      _updateInfo = updateInfo;

      final isVersionNewer = _isUpdateAvailable(
        currentVersion,
        currentBuildNumber,
        updateInfo.latestVersion,
        updateInfo.versionCode,
      );

      final isUpdateAvailable = isVersionNewer;

      if (isUpdateAvailable) {
        final directory = await getApplicationDocumentsDirectory();
        final extension = Platform.isAndroid ? 'apk' : 'msix';
        final fileName = 'auralis-music-${updateInfo.latestVersion}.$extension';
        final filePath = '${directory.path}/auralis/$fileName';
        final file = File(filePath);

        bool isDownloaded = false;
        if (await file.exists()) {
          // if (updateInfo.checksum != null) {
          //   isDownloaded = await _verifyChecksum(
          //     filePath,
          //     updateInfo.checksum!,
          //   );
          // } else {
          //   isDownloaded = true;
          // }
          isDownloaded = true;
        }

        if (isDownloaded) {
          _downloadedFilePath = filePath;
          _setStatus(OTAStatus.downloaded);
        } else {
          _setStatus(OTAStatus.updateAvailable);
        }
      } else {
        _setStatus(showNoUpdateMessage ? OTAStatus.noUpdate : OTAStatus.idle);
      }

      debugPrint('Update check completed: $updateInfo');
    } catch (e) {
      _handleError(OTAError.networkError, 'Failed to check for updates}');
      debugPrint('Error checking for updates: ${e.toString()}');
    }
  }

  bool _isUpdateAvailable(
    String currentVersion,
    int currentBuildNumber,
    String latestVersion,
    int latestBuildNumber,
  ) {
    if (latestBuildNumber > currentBuildNumber) {
      return true;
    }

    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  int _compareVersions(String version1, String version2) {
    final parts1 = version1.split('.').map(int.parse).toList();
    final parts2 = version2.split('.').map(int.parse).toList();

    final maxLength = parts1.length > parts2.length
        ? parts1.length
        : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? parts1[i] : 0;
      final part2 = i < parts2.length ? parts2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  Future<void> downloadUpdate() async {
    if (Platform.isLinux) {
      return;
    }

    if (_updateInfo == null || _status == OTAStatus.downloading) return;

    final directory = await getApplicationDocumentsDirectory();
    final extension = Platform.isAndroid ? 'apk' : 'msix';
    final fileName = 'auralis-music-${_updateInfo!.latestVersion}.$extension';
    final filePath = '${directory.path}/auralis/$fileName';
    final file = File(filePath);

    if (await file.exists()) {
      // bool isValid = false;
      // if (_updateInfo!.checksum != null) {
      //   isValid = await _verifyChecksum(filePath, _updateInfo!.checksum!);
      // } else {
      //   isValid = true;
      // }
      // if (isValid) {
      _downloadedFilePath = filePath;
      _setStatus(OTAStatus.downloaded);
      return;
      // } else {
      //   await file.delete();
      // }
    }

    _setStatus(OTAStatus.downloading);
    _cancelToken = CancelToken();

    try {
      int startTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      await _dio.download(
        _updateInfo!.downloadUrl,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final currentTime = DateTime.now().millisecondsSinceEpoch;
            final timeDiff = currentTime - startTime;
            final bytesDiff = received - lastBytes;

            String downloadSpeed = '0 KB/s';
            String eta = 'Calculating...';

            if (timeDiff > 1000) {
              final speed = (bytesDiff / (timeDiff / 1000));
              downloadSpeed = '${(speed / 1024).toStringAsFixed(1)} KB/s';

              if (speed > 0) {
                final remainingBytes = total - received;
                final remainingSeconds = remainingBytes / speed;
                eta = _formatDuration(remainingSeconds.toInt());
              }

              startTime = currentTime;
              lastBytes = received;
            }

            _downloadProgress = OTADownloadProgress(
              downloaded: received,
              total: total,
              percentage: (received / total) * 100,
              downloadSpeed: downloadSpeed,
              eta: eta,
            );
            notifyListeners();
          }
        },
      );

      // if (_updateInfo!.checksum != null) {
      //   if (!await _verifyChecksum(filePath, _updateInfo!.checksum!)) {
      //     await file.delete();
      //     _handleError(
      //       OTAError.checksumError,
      //       'Downloaded file verification failed',
      //     );
      //     return;
      //   }
      // }

      _downloadedFilePath = filePath;
      _setStatus(OTAStatus.downloaded);
    } catch (e) {
      print('Download error: $e');
      if (!_cancelToken!.isCancelled) {
        _handleError(OTAError.downloadError, 'Download failed}');
      }
    }
  }

  Future<void> installUpdate() async {
    if (Platform.isLinux) {
      // nothing to install via OTA
      return;
    }

    if (_downloadedFilePath == null || _status != OTAStatus.downloaded) return;

    _setStatus(OTAStatus.installing);

    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();

        if (status.isGranted) {
          final result = await AndroidPackageInstaller.installApk(
            apkFilePath: _downloadedFilePath!,
          );

          if (result == 0) {
            _setStatus(OTAStatus.installed);
            await _cleanupDownloadedFile();
          } else {
            _handleError(
              OTAError.installError,
              'Installation failed with code: $result',
            );
          }
        } else {
          _handleError(
            OTAError.permissionError,
            'Permission to install packages denied.',
          );
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command',
          'Add-AppxPackage -Path "$_downloadedFilePath" -ForceApplicationShutdown; '
              r"$pkg = Get-AppxPackage -Name 'com.auralis.app'; "
              r'if ($pkg) { Start-Process "shell:AppsFolder\$($pkg.PackageFamilyName)!App" }',
        ], runInShell: true);

        if (result.exitCode == 0) {
          _setStatus(OTAStatus.installed);
          await _cleanupDownloadedFile();
        } else {
          _handleError(
            OTAError.installError,
            'Installation failed: ${result.stderr}',
          );
        }
      } else {
        _handleError(
          OTAError.installError,
          'Installation not supported on this platform',
        );
      }
    } catch (e) {
      print('Installation error: $e');
      _handleError(OTAError.installError, 'Installation failed}');
    }
  }

  void cancelDownload() {
    if (_cancelToken != null && _status == OTAStatus.downloading) {
      _cancelToken!.cancel('Download cancelled by user');
      _setStatus(OTAStatus.updateAvailable);
      _downloadProgress = null;
      notifyListeners();
    }
  }

  Future<void> skipVersion() async {
    if (_updateInfo != null) {
      _setStatus(OTAStatus.idle);
      _updateInfo = null;
    }
  }

  Future<bool> _verifyChecksum(String filePath, String expectedChecksum) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final calculatedChecksum = 'sha256:${digest.toString()}';
      return calculatedChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  Future<void> _cleanupDownloadedFile() async {
    if (_downloadedFilePath != null) {
      try {
        final file = File(_downloadedFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {}
      _downloadedFilePath = null;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).floor()}m ${seconds % 60}s';
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    return '${hours}h ${minutes}m';
  }

  void _setStatus(OTAStatus status) {
    _status = status;
    notifyListeners();
  }

  void _handleError(OTAError error, String message) {
    _error = error;
    _errorMessage = message;
    _setStatus(OTAStatus.error);
  }

  Future<void> openReleasePage() async {
    const releaseUrl = 'https://github.com/kruthagna-j/auralis-app/releases';
    final uri = Uri.parse(releaseUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void setUpdateUIShown(bool value) {
    _isUpdateUIShown = value;
    notifyListeners();
  }

  void setOTAScreenActive(bool value) {
    _isOTAScreenActive = value;
    notifyListeners();
  }

  void setUpdateChannel(String channel) {
    _updateChannel = channel;
  }

  void reset() {
    _status = OTAStatus.idle;
    _updateInfo = null;
    _downloadProgress = null;
    _error = null;
    _errorMessage = null;
    _downloadedFilePath = null;
    _cancelToken = null;
    _isUpdateUIShown = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _dio.close();
    super.dispose();
  }
}
