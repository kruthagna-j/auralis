import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class SleepTimerBottomSheet extends StatefulWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  State<SleepTimerBottomSheet> createState() => _SleepTimerBottomSheetState();
}

class _SleepTimerBottomSheetState extends State<SleepTimerBottomSheet> {
  Duration _selectedDuration = const Duration(minutes: 30);

  Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor =
        settingsProvider.accentColor ?? Theme.of(context).colorScheme.secondary;
    final isTimerActive = playerProvider.isSleepTimerActive;
    final isDarkMode =
        settingsProvider.theme == 'Dark' ||
        (settingsProvider.theme == 'System Default' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      decoration: BoxDecoration(
        color: MainScreenColors.getSurfaceColor(isDarkMode),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppDimens.dragHandleWidth,
            height: AppDimens.dragHandleHeight,
            margin: const EdgeInsets.only(bottom: AppDimens.spacingLg),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(AppDimens.radiusXxs),
            ),
          ),
          Text(
            'sleep_timer'.tr(),
            style: AppTextStyles.headingLg(
              isDarkMode: isDarkMode,
            ).copyWith(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          const SizedBox(height: AppDimens.spacingXxl),
          if (isTimerActive) ...[
            ValueListenableBuilder<Duration?>(
              valueListenable: playerProvider.sleepTimerRemaining,
              builder: (context, remaining, child) {
                if (remaining == null || remaining <= Duration.zero) {
                  return Text(
                    'timer_expired'.tr(),
                    style: AppTextStyles.subtitle(isDarkMode: isDarkMode)
                        .copyWith(
                          color: MainScreenColors.getTextColor(isDarkMode),
                        ),
                  );
                }
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final minutes = twoDigits(remaining.inMinutes.remainder(60));
                final seconds = twoDigits(remaining.inSeconds.remainder(60));
                final hours = twoDigits(remaining.inHours);
                return Column(
                  children: [
                    Text(
                      '${'remaining'.tr()}:',
                      style: AppTextStyles.caption(isDarkMode: isDarkMode)
                          .copyWith(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.7),
                          ),
                    ),
                    Text(
                      '$hours:$minutes:$seconds',
                      style: AppTextStyles.titleLg(isDarkMode: isDarkMode)
                          .copyWith(
                            color: accentColor,
                            fontWeight: AppTextStyles.weightBold,
                          ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppDimens.spacingLg),
            ElevatedButton.icon(
              onPressed: () {
                playerProvider.cancelSleepTimer();
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.cancel_outlined,
                color: getTextColorForBackground(accentColor),
              ),
              label: Text(
                'cancel_timer'.tr(),
                style: AppTextStyles.button(
                  color: getTextColorForBackground(accentColor),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingXxl,
                  vertical: AppDimens.paddingMd,
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxl),
          ],
          SwitchListTile(
            title: Text(
              'fade_out_effect'.tr(),
              style: AppTextStyles.subtitle(
                isDarkMode: isDarkMode,
              ).copyWith(color: MainScreenColors.getTextColor(isDarkMode)),
            ),
            value: settingsProvider.sleepTimerFadeEnabled,
            onChanged: (value) {
              settingsProvider.sleepTimerFadeEnabled = value;
            },
            activeColor: accentColor,
          ),
          const SizedBox(height: AppDimens.spacingXxl),
          GestureDetector(
            onTap: () async {
              final initialTime = TimeOfDay(
                hour: _selectedDuration.inHours,
                minute: _selectedDuration.inMinutes.remainder(60),
              );
              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
                initialEntryMode: TimePickerEntryMode.dialOnly,
                helpText: 'select_duration'.tr(),
                builder: (context, child) {
                  final mediaQuery = MediaQuery.of(context);
                  return MediaQuery(
                    data: mediaQuery.copyWith(alwaysUse24HourFormat: true),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: accentColor,
                          onPrimary: getTextColorForBackground(accentColor),
                          surface: MainScreenColors.getSurfaceColor(isDarkMode),
                          onSurface: MainScreenColors.getTextColor(isDarkMode),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDuration = Duration(
                    hours: picked.hour,
                    minutes: picked.minute,
                  );
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimens.spacingXxl,
                horizontal: AppDimens.spacingXxl,
              ),
              decoration: BoxDecoration(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: AppDimens.opacitySubtle),
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: AppDimens.opacityOverlay,
                  ),
                  width: AppDimens.borderWidthThin,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'select_duration'.tr(),
                    style: AppTextStyles.caption(isDarkMode: isDarkMode)
                        .copyWith(
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: AppDimens.opacityMuted),
                        ),
                  ),
                  const SizedBox(height: AppDimens.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _selectedDuration.inHours.toString().padLeft(2, '0'),
                        style: AppTextStyles.displayLg(
                          isDarkMode: isDarkMode,
                        ).copyWith(color: accentColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimens.spacingSmMd,
                          left: AppDimens.spacingXxs,
                          right: AppDimens.spacingXxs,
                        ),
                        child: Text(
                          ':',
                          style: AppTextStyles.titleLg(isDarkMode: isDarkMode)
                              .copyWith(
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ).withValues(alpha: AppDimens.opacityMuted),
                              ),
                        ),
                      ),
                      Text(
                        _selectedDuration.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0'),
                        style: AppTextStyles.displayLg(
                          isDarkMode: isDarkMode,
                        ).copyWith(color: accentColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppDimens.spacing4Xl + AppDimens.spacingXxl,
                        child: Center(
                          child: Text(
                            'hrs',
                            style: AppTextStyles.caption(isDarkMode: isDarkMode)
                                .copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: AppDimens.opacitySemi),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: AppDimens.spacingMd + AppDimens.spacingXxs,
                      ),
                      SizedBox(
                        width: AppDimens.spacing4Xl + AppDimens.spacingXxl,
                        child: Center(
                          child: Text(
                            'min',
                            style: AppTextStyles.caption(isDarkMode: isDarkMode)
                                .copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: AppDimens.opacitySemi),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingSm),
                  Icon(
                    Icons.edit_outlined,
                    size: AppDimens.iconSm,
                    color: accentColor.withValues(
                      alpha: AppDimens.opacityMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingXxxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    playerProvider.startSleepTimer(
                      _selectedDuration,
                      fade: settingsProvider.sleepTimerFadeEnabled,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: getTextColorForBackground(accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimens.spacingMdLg,
                    ),
                  ),
                  child: Text(
                    isTimerActive ? 'update_timer'.tr() : 'set_timer'.tr(),
                    style: AppTextStyles.button(
                      color: getTextColorForBackground(accentColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
