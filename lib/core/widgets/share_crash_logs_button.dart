import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../services/crash_log_service.dart';

class ShareCrashLogsButton extends StatelessWidget {
  final String label;
  const ShareCrashLogsButton({Key? key, this.label = 'Share logs'})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async =>
          await GetIt.I<CrashLogService>().shareLogs(context),
      icon: const Icon(Icons.share),
      label: Text(label),
    );
  }
}
