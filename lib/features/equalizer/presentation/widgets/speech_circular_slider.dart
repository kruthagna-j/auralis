import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class SpeechCircularSlider extends StatefulWidget {
  const SpeechCircularSlider({Key? key}) : super(key: key);

  @override
  State<SpeechCircularSlider> createState() => _SpeechCircularSliderState();
}

class _SpeechCircularSliderState extends State<SpeechCircularSlider> {
  double _playbackSpeed = 1.0;
  int _resetKey = 0;

  @override
  void initState() {
    super.initState();
    _initPlaybackSpeed();
  }

  void _initPlaybackSpeed() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    _playbackSpeed = playerProvider.playerService.getPlaybackSpeed();
  }

  void _setPlaybackSpeed(double value) {
    setState(() {
      _playbackSpeed = value;
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      playerProvider.playerService.setPlaybackSpeed(value);
    });
  }

  void _resetPlaybackSpeed() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playerService.setPlaybackSpeed(1.0);
    setState(() {
      _playbackSpeed = 1.0;
      _resetKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final speedColor = HSLColor.fromColor(
      accentColor,
    ).withHue((HSLColor.fromColor(accentColor).hue + 60) % 360).toColor();

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
                    speedColor.withValues(alpha: 0.1),
                    speedColor.withValues(alpha: 0.05),
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
                          Icons.speed_rounded,
                          color: speedColor,
                          size: AppDimens.iconXs,
                        ),
                        SizedBox(width: AppDimens.spacingXs),
                        Text(
                          'Speed',
                          style: AppTextStyles.body2(isDarkMode: isDarkMode)
                              .copyWith(
                                fontWeight: AppTextStyles.weightSemiBold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        SizedBox(width: AppDimens.spacingXs),
                        GestureDetector(
                          onTap: _resetPlaybackSpeed,
                          child: Tooltip(
                            message: 'Reset speed',
                            child: Icon(
                              Icons.replay_rounded,
                              color: speedColor.withValues(alpha: 0.75),
                              size: AppDimens.iconXs * 0.85,
                            ),
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
                            color: speedColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SleekCircularSlider(
                        key: ValueKey('speed_$_resetKey'),
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
                              speedColor.withValues(alpha: 0.7),
                              speedColor,
                              speedColor.withValues(alpha: 0.9),
                            ],
                            shadowColor: speedColor.withValues(alpha: 0.4),
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
                          final display = value.toStringAsFixed(1);
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  display,
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
                                  'x',
                                  style:
                                      AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        fontWeight: AppTextStyles.weightMedium,
                                        color: speedColor,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                        min: 0.5,
                        max: 2.0,
                        initialValue: _playbackSpeed,
                        onChange: _setPlaybackSpeed,
                        onChangeStart: (double value) {},
                        onChangeEnd: (double value) {
                          _setPlaybackSpeed(value);
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
