import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    primaryColor: MainScreenColors.skyBlue,
    scaffoldBackgroundColor: MainScreenColors.lightBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: MainScreenColors.lightSurfaceColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: MainScreenColors.lightTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: MainScreenColors.lightTextColor),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: MainScreenColors.lightTextColor),
      bodyMedium: TextStyle(color: MainScreenColors.lightTextColor),
    ),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    primaryColor: MainScreenColors.skyBlue,
    scaffoldBackgroundColor: MainScreenColors.darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: MainScreenColors.darkSurfaceColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: MainScreenColors.darkTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: MainScreenColors.darkTextColor),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: MainScreenColors.darkTextColor),
      bodyMedium: TextStyle(color: MainScreenColors.darkTextColor),
    ),
  );
}

class FadeForwardsPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeForwardsPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
