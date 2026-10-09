import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../equalizer/presentation/screens/equalizer_screen.dart';
import '../screens/ai_api_config_screen.dart';
import 'settings_item.dart';
import 'custom_dropdown.dart';

class AudioSettingsSection extends StatelessWidget {
  const AudioSettingsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<
      SettingsProvider,
      ({bool isDarkMode, Color accentColor, String language})
    >(
      selector: (context, settingsProvider) => (
        isDarkMode: settingsProvider.themeMode == ThemeMode.dark,
        accentColor: settingsProvider.accentColor,
        language: settingsProvider.language,
      ),
      builder: (context, themeData, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              title: 'audio_settings'.tr(),
              icon: Icons.volume_up,
              isDarkMode: themeData.isDarkMode,
              accentColor: themeData.accentColor,
            ),

            Container(
              decoration: BoxDecoration(
                color: themeData.isDarkMode
                    ? MainScreenColors.darkSurfaceColor
                    : MainScreenColors.lightSurfaceColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: themeData.isDarkMode
                      ? Colors.white.withValues(alpha: AppDimens.opacitySubtle)
                      : Colors.black.withValues(alpha: AppDimens.opacitySubtle),
                  width: AppDimens.borderWidthThin,
                ),
              ),
              child: Column(
                children: [
                  if (Platform.isAndroid ||
                      Platform.isIOS ||
                      Platform.isWindows ||
                      Platform.isLinux)
                    SettingsItem(
                      icon: Icons.equalizer,
                      title: 'equalizer_card_title'.tr(),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: AppDimens.iconXs,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EqualizerScreen(),
                          ),
                        );
                      },
                      isDarkMode: themeData.isDarkMode,
                      accentColor: themeData.accentColor,
                    ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsItem(
                        icon: Icons.stream,
                        title: 'streaming_quality_card_title'.tr(),

                        trailing: CustomDropdown<String>(
                          value: settingsProvider.streamingQuality,
                          items: ['Low', 'Medium', 'High'],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.streamingQuality = value;
                            }
                          },
                          isDarkMode: themeData.isDarkMode,
                          accentColor: themeData.accentColor,
                          subtitle: 'select_streaming_quality'.tr(),
                        ),
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.sd_storage,
                        title: 'audio_cache_enabled'.tr(),
                        value: settingsProvider.audioCacheEnabled,
                        onChanged: (value) {
                          settingsProvider.audioCacheEnabled = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsItem(
                        icon: Icons.download,
                        title: 'downloading_quality_card_title'.tr(),

                        trailing: CustomDropdown<String>(
                          value: settingsProvider.downloadingQuality,
                          items: ['Low', 'Medium', 'High'],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.downloadingQuality = value;
                            }
                          },
                          isDarkMode: themeData.isDarkMode,
                          accentColor: themeData.accentColor,
                          subtitle: 'select_downloading_quality'.tr(),
                        ),
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.wifi,
                        title: 'wifi_only_downloads'.tr(),
                        value: settingsProvider.wifiOnlyDownloads,
                        onChanged: (value) {
                          settingsProvider.wifiOnlyDownloads = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsItem(
                        icon: Icons.download_for_offline,
                        title: 'concurrent_downloads'.tr(),

                        trailing: CustomDropdown<String>(
                          value: settingsProvider.maxConcurrentDownloads
                              .toString(),
                          items: ['1', '2', '3', '4'],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.maxConcurrentDownloads =
                                  int.parse(value);
                            }
                          },
                          isDarkMode: themeData.isDarkMode,
                          accentColor: themeData.accentColor,
                          subtitle: 'select_max_concurrent_downloads'.tr(),
                        ),
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.high_quality,
                        title: 'jio_saavn_card_title'.tr(),
                        value: settingsProvider.jioSaavnEnabled,
                        onChanged: (value) {
                          settingsProvider.jioSaavnEnabled = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.queue_music,
                        title: 'gapless_playback'.tr(),
                        value: settingsProvider.gaplessPlaybackEnabled,
                        onChanged: (value) {
                          settingsProvider.gaplessPlaybackEnabled = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsItem(
                        icon: Icons.music_note,
                        title: 'lyrics_provider_card_title'.tr(),

                        trailing: CustomDropdown<String>(
                          value: settingsProvider.lyricsProvider,
                          items: ['LRCLib', 'YT Music', 'AI'],
                          onChanged: (value) {
                            if (value != null) {
                              settingsProvider.lyricsProvider = value;
                            }
                          },
                          isDarkMode: themeData.isDarkMode,
                          accentColor: themeData.accentColor,
                          subtitle: 'select_lyrics_provider'.tr(),
                        ),
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      if (settingsProvider.lyricsProvider != 'AI') {
                        return const SizedBox.shrink();
                      }
                      return SettingsItem(
                        icon: Icons.vpn_key,
                        title: 'ai_api_config_card_title'.tr(),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: AppDimens.iconXs,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiApiConfigScreen(),
                            ),
                          );
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.history,
                        title: 'playback_history_card_title'.tr(),
                        value: settingsProvider.playbackHistoryEnabled,
                        onChanged: (value) {
                          settingsProvider.playbackHistoryEnabled = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: themeData.isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                  ),

                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsToggleItem(
                        icon: Icons.search,
                        title: 'search_history_card_title'.tr(),
                        value: settingsProvider.searchHistoryEnabled,
                        onChanged: (value) {
                          settingsProvider.searchHistoryEnabled = value;
                        },
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
