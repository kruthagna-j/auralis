import 'package:flutter/material.dart';

class MainScreenColors {
  static const primaryPurple = Color(0xFF6C63FF);
  static const secondaryPink = Color(0xFFFF63B8);
  static const skyBlue = Color(0xFF7250A8); // Auralis accent (was 0xFF63B8FF)
  static const backgroundColor = Color(0xFF1A1A1A);
  static const textColor = Color(0xFFFFFFFF);

  static const darkPrimaryPurple = Color(0xFF6C63FF);
  static const darkSecondaryPink = Color(0xFFFF63B8);
  static const darkBackgroundColor = Color(0xFF1A1A1A);
  static const darkSurfaceColor = Color(0xFF2A2A2A);
  static const darkTextColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFF2A2A2A);
  static const darkTirtiaryColor = Color(0xFF63FF6C);

  static const lightPrimaryPurple = Color(0xFF6C63FF);
  static const lightSecondaryPink = Color(0xFFFF63B8);
  static const lightBackgroundColor = Color(0xFFF5F5F5);
  static const lightSurfaceColor = Color(0xFFFFFFFF);
  static const lightTextColor = Color(0xFF000000);
  static const lightTirtiaryColor = Color(0xFF63FF6C);

  static const List<Color> accentColors = [
    secondaryPink,
    skyBlue,
    Color(0xFFFF6363),
    Color(0xFF6C63FF),
    Color(0xFFB863FF),
    Color(0xFFFF63FF),
    Color(0xFFB8860B),
    Color(0xFF3F51B5),
    Color(0xFFFF7F50),
    Color(0xFF808000),
  ];

  static Color getPrimaryColor(bool isDarkMode) =>
      isDarkMode ? darkPrimaryPurple : lightPrimaryPurple;

  static Color getSecondaryColor(bool isDarkMode) =>
      isDarkMode ? darkSecondaryPink : lightSecondaryPink;

  static Color getTirtiaryColor(bool isDarkMode) =>
      isDarkMode ? darkTirtiaryColor : lightTirtiaryColor;

  static Color getBackgroundColor(bool isDarkMode) =>
      isDarkMode ? darkBackgroundColor : lightBackgroundColor;

  static Color getSurfaceColor(bool isDarkMode) =>
      isDarkMode ? darkSurfaceColor : lightSurfaceColor;

  static Color getTextColor(bool isDarkMode) =>
      isDarkMode ? darkTextColor : lightTextColor;
}
