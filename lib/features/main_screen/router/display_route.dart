import 'package:flutter/material.dart';

import '../presentation/screens/desktop_screen.dart';
import '../presentation/screens/mobile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const MobileMainScreen(key: ValueKey('MobileMainScreen'));
    } else {
      return const DesktopMainScreen(key: ValueKey('DesktopMainScreen'));
    }
  }
}
