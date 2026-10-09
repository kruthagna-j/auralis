import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

class VideoModeDialog extends StatelessWidget {
  final Color accentColor;

  const VideoModeDialog({Key? key, required this.accentColor})
    : super(key: key);

  static void show(BuildContext context, {required Color accentColor}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoModeDialog(accentColor: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isWide = constraints.maxWidth >= 600 || screenWidth >= 800;
          final dialogWidth = isWide ? 700.0 : null;

          final padding = EdgeInsets.all(
            isWide ? AppDimens.spacingXxxl : AppDimens.spacingXxl,
          );
          final iconSize = isWide ? AppDimens.iconHero : AppDimens.iconXxl;
          final titleStyle = isWide
              ? AppTextStyles.display(isDarkMode: isDarkMode)
              : AppTextStyles.headingLg(isDarkMode: isDarkMode);
          final bodyStyle = isWide
              ? AppTextStyles.titleSm(isDarkMode: isDarkMode)
              : AppTextStyles.subtitle(isDarkMode: isDarkMode);

          Widget buildIcon() => Container(
            padding: EdgeInsets.all(
              isWide ? AppDimens.paddingXl : AppDimens.paddingLg,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library,
              color: accentColor,
              size: iconSize,
            ),
          );

          final description = 'video_mode_description'.tr();

          return Center(
            child: Container(
              width: dialogWidth,
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MainScreenColors.getSurfaceColor(
                      isDarkMode,
                    ).withValues(alpha: 0.95),
                    MainScreenColors.getSurfaceColor(
                      isDarkMode,
                    ).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: AppDimens.borderWidthThin,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: AppDimens.elevationHigh,
                    offset: const Offset(0, AppDimens.spacingSmMd),
                  ),
                ],
              ),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildIcon(),
                        SizedBox(width: AppDimens.spacingXxl),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'video_mode'.tr(),
                                style: titleStyle.copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppDimens.paddingSm),
                              Text(
                                description,
                                textAlign: TextAlign.left,
                                style: bodyStyle.copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: 0.8),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppDimens.spacingXl),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: AppDimens.buttonWidthMedium,
                                  height: AppDimens.buttonHeightMedium,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXxxl,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppDimens.radiusXxxl,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'got_it'.tr(),
                                        style: AppTextStyles.button(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        buildIcon(),
                        const SizedBox(height: AppDimens.spacingLg),
                        Text(
                          'video_mode'.tr(),
                          style: titleStyle.copyWith(
                            color: MainScreenColors.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: AppDimens.spacingMd),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: bodyStyle.copyWith(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppDimens.spacingXxl),
                        Container(
                          width: double.infinity,
                          height: AppDimens.buttonHeightMedium,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusXxxl,
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusXxxl,
                                ),
                              ),
                            ),
                            child: Text(
                              'got_it'.tr(),
                              style: AppTextStyles.button(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
