import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/settings_provider.dart';

class EqualizerBandSlider extends StatelessWidget {
  final double gain;
  final double minDecibels;
  final double maxDecibels;
  final double centerFrequency;
  final bool isEnabled;
  final ValueChanged<double> onChanged;

  const EqualizerBandSlider({
    Key? key,
    required this.gain,
    required this.minDecibels,
    required this.maxDecibels,
    required this.centerFrequency,
    required this.isEnabled,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: accentColor,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.white,
                trackHeight: AppDimens.sliderTrackHeight,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: AppDimens.iconXs / 2,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: AppDimens.iconXs,
                ),
              ),
              child: Slider(
                value: gain.clamp(minDecibels, maxDecibels),
                min: minDecibels,
                max: maxDecibels,
                onChanged: isEnabled ? onChanged : null,
              ),
            ),
          ),
        ),
        SizedBox(height: AppDimens.spacingSm),
        Text(
          centerFrequency >= 1000
              ? '${(centerFrequency / 1000).toStringAsFixed(1)}kHz'
              : '${centerFrequency.round()}Hz',
          style: AppTextStyles.caption(
            isDarkMode: isDarkMode,
          ).copyWith(color: MainScreenColors.getTextColor(isDarkMode)),
        ),
        SizedBox(height: AppDimens.spacingXxxl),
      ],
    );
  }
}
