import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Thumbnail;

import '../../../../core/providers/queued_provider.dart';
import '../../data/services/home_screen_queue_service.dart';
import '../../../../shared/components/app_snackbar.dart';

void handleSongTap(BuildContext context, Map<String, dynamic> song) {
  try {
    playSong(context, song);
  } catch (e) {
    showErrorSnackbar(context, 'unable_to_play_the_song_please_try_again'.tr());
    debugPrint('Error playing song: $e');
  }
}

Future<void> playSong(BuildContext context, Map<String, dynamic> song) async {
  try {
    final queueService = HomeScreenQueueService(context);
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    await queueService.playAndQueueSongs(song);
    await queueProvider.saveQueue();
  } catch (e) {
    String errorMessage = 'failed_to_play_song_please_try_again'.tr();

    if (e.toString().contains('Video ID not found')) {
      errorMessage = 'invalid_song_data'.tr();
    } else if (e is VideoUnavailableException) {
      errorMessage = 'this_song_is_currently_unavailable'.tr();
    }

    showErrorSnackbar(context, errorMessage);
    debugPrint('Error playing song(home screen): $e');
  }
}

void showErrorSnackbar(BuildContext context, String message) {
  AppSnackBar.showError(context, message);
}
