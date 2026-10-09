import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ColorPaletteService {
  static const Color _defaultColor = Color(0xFF1E1E1E);

  static Future<Color> generatePalette(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return _defaultColor;

      final ImageProvider provider = _providerFor(imageUrl);

      final ui.Image image = await _resolveImage(provider);

      final int width = image.width;

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();

      if (byteData == null) return _defaultColor;

      final Uint8List pixels = byteData.buffer.asUint8List();

      final int colorValue = await compute(
        _extractDominantColor,
        _PixelData(pixels, width),
      );
      return Color(colorValue);
    } catch (e) {
      debugPrint('Error generating color palette: $e');
      return _defaultColor;
    }
  }

  static ImageProvider _providerFor(String url) {
    if (url.startsWith('file://') ||
        url.startsWith('/') ||
        url.contains('\\')) {
      String filePath = url;
      if (url.startsWith('file://')) filePath = url.substring(7);
      return ResizeImage(FileImage(File(filePath)), width: 64, height: 64);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ResizeImage(
        CachedNetworkImageProvider(url),
        width: 64,
        height: 64,
      );
    }
    throw ArgumentError('Unsupported image URL: $url');
  }

  static Future<ui.Image> _resolveImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image.clone());
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static int _extractDominantColor(_PixelData data) {
    return _dominantColorFromRgba(data.pixels, data.width);
  }

  static int _dominantColorFromRgba(Uint8List pixels, int width) {
    if (pixels.length < 4) return _defaultColor.value;

    final counts = <int, int>{};
    final sumR = <int, int>{};
    final sumG = <int, int>{};
    final sumB = <int, int>{};

    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];

      if (a < 128) continue;

      if (r + g + b < 30 || r + g + b > 720) continue;

      final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      counts[key] = (counts[key] ?? 0) + 1;
      sumR[key] = (sumR[key] ?? 0) + r;
      sumG[key] = (sumG[key] ?? 0) + g;
      sumB[key] = (sumB[key] ?? 0) + b;
    }

    if (counts.isEmpty) return _defaultColor.value;

    int bestKey = counts.keys.first;
    int bestCount = counts[bestKey]!;
    for (final entry in counts.entries) {
      if (entry.value > bestCount) {
        bestKey = entry.key;
        bestCount = entry.value;
      }
    }

    final avgR = sumR[bestKey]! ~/ bestCount;
    final avgG = sumG[bestKey]! ~/ bestCount;
    final avgB = sumB[bestKey]! ~/ bestCount;

    return (0xFF000000 | (avgR << 16) | (avgG << 8) | avgB);
  }
}

class _PixelData {
  final Uint8List pixels;
  final int width;
  const _PixelData(this.pixels, this.width);
}
