import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class VolumeCircularSlider extends StatefulWidget {
  const VolumeCircularSlider({Key? key}) : super(key: key);

  @override
  State<VolumeCircularSlider> createState() => _VolumeCircularSliderState();
}

class _VolumeCircularSliderState extends State<VolumeCircularSlider> {
  double _volume = 1.0;

  Color _volumeColor(double value) {
    if (value <= 0.6) return Colors.green;
    if (value <= 1.0) return Colors.amber;
    return Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _initVolume();
  }

  void _initVolume() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _volume = settingsProvider.volumeLevel.clamp(0.0, 1.5);
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value.clamp(0.0, 1.5);
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      playerProvider.playerService.setVolume(_volume);
      Provider.of<SettingsProvider>(context, listen: false).volumeLevel =
          _volume;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final volumeColor = _volumeColor(_volume);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AppDimens.headerImageMd;
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final scaledMax = (AppDimens.headerImageMd / textScale).clamp(
          AppDimens.thumbnailLarge * 1.0,
          AppDimens.headerImageMd,
        );
        final sliderSize = (available * 0.75).clamp(
          AppDimens.thumbnailLarge * 1.0,
          scaledMax,
        );

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppDimens.shimmerHorizontalSection,
            ),
            child: Container(
              padding: EdgeInsets.all(AppDimens.paddingMd),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    volumeColor.withValues(alpha: 0.12),
                    volumeColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.volume_up_rounded,
                          color: volumeColor,
                          size: AppDimens.iconXs,
                        ),
                        SizedBox(width: AppDimens.spacingXs),
                        Text(
                          'Volume',
                          style: AppTextStyles.body2(isDarkMode: isDarkMode)
                              .copyWith(
                                fontWeight: AppTextStyles.weightSemiBold,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimens.spacingSm),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusFull * 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: volumeColor.withValues(alpha: 0.24),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SleekCircularSlider(
                        appearance: CircularSliderAppearance(
                          customWidths: CustomSliderWidths(
                            trackWidth: AppDimens.progressStroke * 2.5,
                            progressBarWidth: AppDimens.progressStroke * 4,
                            shadowWidth: AppDimens.elevationHigh * 2.5,
                          ),
                          customColors: CustomSliderColors(
                            trackColor: isDarkMode
                                ? Colors.grey[800]!
                                : Colors.grey[300]!,
                            progressBarColors: [
                              volumeColor.withValues(alpha: 0.7),
                              volumeColor,
                              volumeColor.withValues(alpha: 0.9),
                            ],
                            shadowColor: volumeColor.withValues(alpha: 0.4),
                            shadowMaxOpacity: 0.6,
                            dotColor: Colors.white,
                          ),
                          infoProperties: InfoProperties(
                            topLabelText: '',
                            bottomLabelText: '',
                            modifier: (double value) => '',
                            mainLabelStyle: AppTextStyles.titleLg(
                              isDarkMode: isDarkMode,
                            ).copyWith(fontWeight: AppTextStyles.weightBold),
                          ),
                          startAngle: 135,
                          angleRange: 270,
                          size: sliderSize,
                          animationEnabled: true,
                        ),
                        innerWidget: (double value) {
                          final percent = (value * 100).toInt();
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$percent',
                                  style:
                                      AppTextStyles.titleLg(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        fontWeight: AppTextStyles.weightBold,
                                        color: MainScreenColors.getTextColor(
                                          isDarkMode,
                                        ),
                                      ),
                                ),
                                SizedBox(height: AppDimens.spacingXs),
                                Text(
                                  '%',
                                  style:
                                      AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        fontWeight: AppTextStyles.weightMedium,
                                        color: volumeColor,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                        min: 0.0,
                        max: 1.5,
                        initialValue: _volume,
                        onChange: _setVolume,
                        onChangeStart: (double value) {},
                        onChangeEnd: (double value) {
                          _setVolume(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
