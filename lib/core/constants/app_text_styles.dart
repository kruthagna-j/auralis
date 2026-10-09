import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimens.dart';

class AppTextStyles {
  AppTextStyles._();
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  static const double fontSizeXxs = 8.0;
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 11.0;
  static const double fontSizeCaption = 12.0;
  static const double fontSizeBody2 = 13.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeBodyLg = 15.0;
  static const double fontSizeSubtitle = 16.0;
  static const double fontSizeTitle = 18.0;
  static const double fontSizeTitleLg = 20.0;
  static const double fontSizeHeading = 22.0;
  static const double fontSizeHeadingLg = 24.0;
  static const double fontSizeDisplay = 28.0;
  static const double fontSizeDisplayLg = 32.0;
  static const double fontSizeHero = 48.0;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
  static const double lineHeightDefault = 1.2;
  static const double lineHeightBody = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static TextStyle badgeBase() =>
      GoogleFonts.poppins(fontSize: fontSizeXxs, fontWeight: weightSemiBold);
  static TextStyle finePrintBase() =>
      GoogleFonts.poppins(fontSize: fontSizeXs, fontWeight: weightRegular);
  static TextStyle captionBase() =>
      GoogleFonts.poppins(fontSize: fontSizeCaption, fontWeight: weightRegular);
  static TextStyle body2Base() =>
      GoogleFonts.poppins(fontSize: fontSizeBody2, fontWeight: weightRegular);
  static TextStyle bodyBase() =>
      GoogleFonts.poppins(fontSize: fontSizeBody, fontWeight: weightRegular);
  static TextStyle bodyLgBase() =>
      GoogleFonts.poppins(fontSize: fontSizeBodyLg, fontWeight: weightMedium);
  static TextStyle subtitleBase() =>
      GoogleFonts.poppins(fontSize: fontSizeSubtitle, fontWeight: weightMedium);
  static TextStyle titleBase() =>
      GoogleFonts.poppins(fontSize: fontSizeTitle, fontWeight: weightSemiBold);
  static TextStyle titleLgBase() => GoogleFonts.poppins(
    fontSize: fontSizeTitleLg,
    fontWeight: weightSemiBold,
  );
  static TextStyle headingBase() => GoogleFonts.poppins(
    fontSize: fontSizeHeading,
    fontWeight: weightSemiBold,
  );
  static TextStyle headingLgBase() =>
      GoogleFonts.poppins(fontSize: fontSizeHeadingLg, fontWeight: weightBold);
  static TextStyle displayBase() =>
      GoogleFonts.poppins(fontSize: fontSizeDisplay, fontWeight: weightBold);
  static TextStyle displayLgBase() =>
      GoogleFonts.poppins(fontSize: fontSizeDisplayLg, fontWeight: weightBold);
  static TextStyle heroBase() =>
      GoogleFonts.poppins(fontSize: fontSizeHero, fontWeight: weightBold);

  static TextStyle badge({bool isDarkMode = true, Color? color}) => badgeBase()
      .copyWith(color: color ?? MainScreenColors.getTextColor(isDarkMode));

  static TextStyle finePrint({bool isDarkMode = true, Color? color}) =>
      finePrintBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle caption({bool isDarkMode = true, Color? color}) =>
      captionBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle body2({bool isDarkMode = true, Color? color}) => body2Base()
      .copyWith(color: color ?? MainScreenColors.getTextColor(isDarkMode));

  static TextStyle bodyMd({bool isDarkMode = true, Color? color}) => bodyBase()
      .copyWith(color: color ?? MainScreenColors.getTextColor(isDarkMode));

  static TextStyle bodyLg({bool isDarkMode = true, Color? color}) =>
      bodyLgBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle subtitle({bool isDarkMode = true, Color? color}) =>
      subtitleBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle titleSm({bool isDarkMode = true, Color? color}) =>
      titleBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle titleLg({bool isDarkMode = true, Color? color}) =>
      titleLgBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle heading({bool isDarkMode = true, Color? color}) =>
      headingBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle headingLg({bool isDarkMode = true, Color? color}) =>
      headingLgBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle display({bool isDarkMode = true, Color? color}) =>
      displayBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle displayLg({bool isDarkMode = true, Color? color}) =>
      displayLgBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
      );

  static TextStyle hero({bool isDarkMode = true, Color? color}) => heroBase()
      .copyWith(color: color ?? MainScreenColors.getTextColor(isDarkMode));
  static TextStyle appBarTitle({bool isDarkMode = true}) =>
      headingLg(isDarkMode: isDarkMode);
  static TextStyle sectionHeader({required Color accentColor}) =>
      titleBase().copyWith(color: accentColor);
  static TextStyle settingsItem({bool isDarkMode = true}) =>
      subtitleBase().copyWith(color: MainScreenColors.getTextColor(isDarkMode));
  static TextStyle settingsSubtitle({bool isDarkMode = true}) =>
      body2Base().copyWith(
        color: MainScreenColors.getTextColor(isDarkMode).withValues(alpha: 0.7),
      );
  static TextStyle queueItemPlaying({
    bool isDarkMode = true,
    required Color accentColor,
  }) => bodyBase().copyWith(color: accentColor, fontWeight: weightSemiBold);
  static TextStyle queueItem({bool isDarkMode = true}) => bodyBase().copyWith(
    color: MainScreenColors.getTextColor(isDarkMode),
    fontWeight: weightMedium,
  );
  static TextStyle playerTitle() => GoogleFonts.poppins(
    fontWeight: weightBold,
    color: Colors.white,
    shadows: [
      const Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2)),
    ],
  );
  static TextStyle playerArtist() =>
      GoogleFonts.poppins(fontWeight: weightRegular, color: Colors.white70);
  static TextStyle lyrics({bool isHighlighted = false, Color? accentColor}) =>
      GoogleFonts.poppins(
        fontSize: isHighlighted ? fontSizeSubtitle : fontSizeBody,
        fontWeight: isHighlighted ? weightSemiBold : weightRegular,
        color: isHighlighted
            ? (accentColor ?? Colors.white)
            : Colors.white.withValues(alpha: 0.5),
        height: lineHeightRelaxed,
      );
  static TextStyle otaBannerTitle({bool isDarkMode = true}) =>
      subtitleBase().copyWith(
        color: MainScreenColors.getTextColor(isDarkMode),
        fontWeight: weightSemiBold,
      );
  static TextStyle otaBannerSubtitle({bool isDarkMode = true}) =>
      captionBase().copyWith(
        color: MainScreenColors.getTextColor(isDarkMode).withValues(alpha: 0.7),
      );
  static TextStyle chipLabel({bool isDarkMode = true, Color? color}) =>
      captionBase().copyWith(
        color: color ?? MainScreenColors.getTextColor(isDarkMode),
        fontWeight: weightMedium,
      );
  static TextStyle toggleOption({
    required bool isSelected,
    required Color accentColor,
    double scale = 1.0,
  }) => GoogleFonts.poppins(
    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
    fontWeight: isSelected ? weightBold : weightRegular,
    fontSize: fontSizeBody * scale,
  );
  static TextStyle bottomSheetTitle({bool isDarkMode = true}) =>
      titleBase().copyWith(color: MainScreenColors.getTextColor(isDarkMode));
  static TextStyle button({Color? color}) => GoogleFonts.poppins(
    fontSize: fontSizeBody,
    fontWeight: weightSemiBold,
    color: color ?? Colors.white,
  );
  static TextStyle actionLabel() => GoogleFonts.poppins(
    fontSize: fontSizeCaption,
    fontWeight: weightMedium,
    color: Colors.white.withValues(alpha: 0.9),
  );

  static const double maxTextScaleFactor = 1.0;

  static Widget Function(BuildContext, Widget?) get appBuilder {
    return (BuildContext context, Widget? child) {
      final currentScaler = MediaQuery.textScalerOf(context);
      final clampedScaler = currentScaler.clamp(
        minScaleFactor: 0.8,
        maxScaleFactor: maxTextScaleFactor,
      );
      final uiScale = AppDimens.scaleFactor(context);
      final iconTheme = IconTheme.of(context);
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: clampedScaler),
        child: IconTheme(
          data: iconTheme.copyWith(size: (iconTheme.size ?? 24.0) * uiScale),
          child: child!,
        ),
      );
    };
  }
}
