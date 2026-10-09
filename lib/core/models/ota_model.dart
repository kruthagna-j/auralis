class OTAUpdateInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final DateTime releaseDate;
  final List<String> updateLog;
  final List<String> features;
  final List<String> bugFixes;
  final String size;
  final String? checksum;
  final String releaseNotes;

  OTAUpdateInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseDate,
    required this.updateLog,
    required this.features,
    required this.bugFixes,
    required this.size,
    this.checksum,
    required this.releaseNotes,
  });

  factory OTAUpdateInfo.fromJson(
    Map<String, dynamic> json, {
    String? deviceAbi,
  }) {
    String downloadUrl;
    String size;
    String? checksum;

    final abis = json['abis'] as Map<String, dynamic>?;
    if (abis != null && deviceAbi != null) {
      final abiData =
          abis[deviceAbi] as Map<String, dynamic>? ??
          abis['arm64-v8a'] as Map<String, dynamic>? ??
          abis.values.first as Map<String, dynamic>;
      downloadUrl = abiData['downloadUrl'] as String;
      size = abiData['size'] as String;
      checksum = abiData['checksum'] as String?;
    } else {
      downloadUrl = json['downloadUrl'] as String;
      size = json['size'] as String;
      checksum = json['checksum'] as String?;
    }

    return OTAUpdateInfo(
      latestVersion: json['latestVersion'] as String,
      versionCode: json['versionCode'] as int,
      downloadUrl: downloadUrl,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      updateLog: List<String>.from(json['updateLog'] as List),
      features: List<String>.from(json['features'] as List),
      bugFixes: List<String>.from(json['bugFixes'] as List),
      size: size,
      checksum: checksum,
      releaseNotes: json['releaseNotes'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseDate': releaseDate.toIso8601String(),
      'updateLog': updateLog,
      'features': features,
      'bugFixes': bugFixes,
      'size': size,
      'checksum': checksum,
      'releaseNotes': releaseNotes,
    };
  }

  @override
  String toString() {
    return 'OTAUpdateInfo(latestVersion: $latestVersion, versionCode: $versionCode)';
  }
}

enum OTAStatus {
  idle,
  checking,
  updateAvailable,
  downloading,
  downloaded,
  installing,
  installed,
  error,
  noUpdate,
}

enum OTAError {
  networkError,
  downloadError,
  installError,
  parseError,
  permissionError,
  storageError,
  checksumError,
  unknownError,
}

class OTADownloadProgress {
  final int downloaded;
  final int total;
  final double percentage;
  final String downloadSpeed;
  final String eta;

  OTADownloadProgress({
    required this.downloaded,
    required this.total,
    required this.percentage,
    required this.downloadSpeed,
    required this.eta,
  });

  String get formattedDownloaded => _formatBytes(downloaded);
  String get formattedTotal => _formatBytes(total);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
