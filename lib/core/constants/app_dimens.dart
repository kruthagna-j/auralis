import 'package:flutter/material.dart';

class AppDimens {
  AppDimens._();
  static const double breakpointSmallMobile = 360.0;
  static const double breakpointScaleBase = 400.0;
  static const double breakpointTabletShort = 500.0;
  static const double breakpointMobile = 600.0;
  static const double breakpointWideScreen = 720.0;
  static const double breakpointDesktop = 800.0;
  static const double breakpointDesktopLarge = 900.0;
  static const double breakpointExtraWide = 1200.0;
  static const double maxContentWidth = 1200.0;
  static const double maxModalWidth = 1400.0;
  static const double dragOffsetMax = 150.0;
  static const double sheetHeightFactor = 0.95;
  static const double opacityHigh = 0.9;
  static const double shadowOffsetSmall = -2.0;
  static const double songInfoCompactWidth = 180.0;
  static const double widePlayerProgressWidthFactor = 0.3;
  static const double inlineSliderWidth = 120.0;
  static const double thumbRadius = 6.0;
  static const double overlayRadius = 12.0;

  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingS = 6.0;
  static const double spacingSm = 8.0;
  static const double spacingSmMd = 10.0;
  static const double spacingMd = 12.0;
  static const double spacingMdLg = 14.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;
  static const double spacingXxxl = 32.0;
  static const double spacing4Xl = 40.0;
  static const double spacing5Xl = 48.0;
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 12.0;
  static const double paddingLg = 16.0;
  static const double paddingXl = 20.0;
  static const double paddingXxl = 24.0;
  static const double radiusXxs = 2.0;
  static const double radiusXs = 4.0;
  static const double radiusS = 6.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 12.0;
  static const double radiusMdLg = 14.0;
  static const double radiusXl = 16.0;
  static const double radiusXxl = 20.0;
  static const double radiusXxxl = 24.0;
  static const double radiusAvatar = 28.0;
  static const double radiusFull = 30.0;
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  static const double iconXxs = 14.0;
  static const double iconXs = 16.0;
  static const double iconSm = 18.0;
  static const double iconMd = 20.0;
  static const double iconMdLg = 22.0;
  static const double iconLg = 24.0;
  static const double iconXl = 28.0;
  static const double iconXxl = 30.0;
  static const double iconHero = 48.0;
  static const double iconStatus = 64.0;
  static const double iconSplash = 80.0;
  static const double miniPlayerHeightCompact = 60.0;
  static const double miniPlayerHeight = 75.0;
  static const double miniPlayerHeightWide = 80.0;
  static const double thumbnailMini = 40.0;
  static const double thumbnailDefault = 50.0;
  static const double thumbnailLarge = 60.0;
  static const double songTileImage = 48.0;
  static const double buttonSizeCompact = 36.0;
  static const double buttonSizeDefault = 40.0;
  static const double buttonSizeLg = 44.0;
  static const double shimmerListTile = 56.0;
  static const double shimmerArtwork = 60.0;
  static const double shimmerCardImage = 128.0;
  static const double shimmerGridItem = 160.0;
  static const double shimmerSection = 200.0;
  static const double shimmerHorizontalSection = 230.0;
  static const double chartHeight = 220.0;
  static const double headerImageSm = 120.0;
  static const double headerImageMd = 138.0;
  static const double sliderTrackHeight = 3.0;
  static const double dragHandleWidth = 36.0;
  static const double dragHandleHeight = 4.0;
  static const double dividerHeight = 1.0;
  static const double progressSmall = 16.0;
  static const double progressStroke = 2.0;
  static const double opacitySubtle = 0.06;
  static const double opacityLight = 0.1;
  static const double opacityMedium = 0.2;
  static const double opacityOverlay = 0.3;
  static const double opacitySemi = 0.5;
  static const double opacityMuted = 0.7;
  static const double opacityFaded = 0.8;
  static const double opacityMid = 0.6;
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animDefault = Duration(milliseconds: 300);
  static const Duration animSmooth = Duration(milliseconds: 500);
  static const Duration animSlow = Duration(milliseconds: 800);
  static const Duration animLong = Duration(milliseconds: 1000);

  static const double iconHuge = 100.0;
  static const double progressCircleLarge = 350.0;
  static const double progressStrokeLg = 10.0;

  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightMedium = 50.0;
  static const double buttonWidthMedium = 200.0;
  static const double borderWidthThin = 1.0;
  static const double borderWidthThick = 1.5;
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointSmallMobile;
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < breakpointMobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= breakpointTabletShort;
  static bool isWideScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointWideScreen;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointDesktop;
  static bool isDesktopLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= breakpointDesktopLarge;
  static int settingsColumns(double width) {
    if (width >= breakpointExtraWide) return 3;
    if (width >= breakpointDesktopLarge) return 2;
    return 1;
  }

  static double scaleFactor(BuildContext context) =>
      (MediaQuery.of(context).size.width / breakpointScaleBase).clamp(0.8, 1.0);
}
