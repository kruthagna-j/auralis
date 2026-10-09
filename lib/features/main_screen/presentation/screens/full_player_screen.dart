import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../player/presentation/screens/player_ui.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final animationType = Provider.of<SettingsProvider>(
      context,
      listen: true,
    ).animationType;
    return Scaffold(
      backgroundColor: animationType == 'Default'
          ? Colors.transparent
          : const Color(0xFF040404),
      body: PlayerUI(
        showFullScreen: true,
        isBottomSheet: true,
        onMinimize: () => Navigator.of(context).pop(),
        onExpand: () {},
      ),
    );
  }
}
