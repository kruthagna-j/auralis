import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/ota_model.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../main_screen/presentation/screens/full_player_screen.dart';
import '../../../ota/data/providers/ota_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../player/presentation/screens/player_ui.dart';
import '../widgets/general_settings_section.dart';
import '../widgets/appearance_settings_section.dart';
import '../widgets/audio_settings_section.dart';
import '../widgets/settings_item.dart';
import 'export_import_settings.dart';
import 'about_screen.dart';
import '../../../ota/presentation/screens/ota_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      if (settingsProvider.updateCheckEnabled) {
        final otaProvider = Provider.of<OTAProvider>(context, listen: false);
        if (otaProvider.status == OTAStatus.idle &&
            otaProvider.updateInfo == null) {
          otaProvider.checkForUpdates();
        }
      }
    });
  }

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
        return SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: themeData.isDarkMode
                ? MainScreenColors.darkBackgroundColor
                : MainScreenColors.lightBackgroundColor,
            appBar: AppBar(
              backgroundColor: themeData.isDarkMode
                  ? Colors.transparent
                  : MainScreenColors.getSurfaceColor(false),
              elevation: 0,
              title: Text(
                'settings'.tr(),
                style: AppTextStyles.headingLg(
                  isDarkMode: themeData.isDarkMode,
                ),
              ),
              // leading: IconButton(
              //   icon: Icon(
              //     Icons.arrow_back,
              //     color: MainScreenColors.getTextColor(themeData.isDarkMode),
              //   ),
              //   onPressed: () => Navigator.pop(context),
              // ),
              centerTitle: false,
            ),
            body: Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                final hasPlayer =
                    playerProvider.currentSong != null ||
                    playerProvider.lastPlayedSong != null ||
                    playerProvider.currentLocalSong != null;

                final mq = MediaQuery.of(context);
                final double navIconScale = mq.textScaleFactor > 1.0
                    ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
                    : 1.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppDimens.paddingLg),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final int columns =
                                width >= AppDimens.breakpointExtraWide
                                ? 3
                                : (width >= AppDimens.breakpointDesktopLarge
                                      ? 2
                                      : 1);
                            final spacing = AppDimens.spacingLg;
                            final columnWidth = columns == 1
                                ? double.infinity
                                : (width - (columns - 1) * spacing) / columns;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<OTAProvider>(
                                  builder: (context, otaProvider, child) {
                                    if (otaProvider.hasUpdate) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: AppDimens.spacingMd,
                                        ),
                                        child: _buildUpdateBanner(
                                          context,
                                          otaProvider,
                                          themeData.isDarkMode,
                                          themeData.accentColor,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),

                                Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    SizedBox(
                                      width: columnWidth,
                                      child: const GeneralSettingsSection(),
                                    ),

                                    SizedBox(
                                      width: columnWidth,
                                      child: const AppearanceSettingsSection(),
                                    ),

                                    SizedBox(
                                      width: columnWidth,
                                      child: const AudioSettingsSection(),
                                    ),

                                    SizedBox(
                                      width: columnWidth,
                                      child: _buildAppUpdatesSection(
                                        context,
                                        themeData.isDarkMode,
                                        themeData.accentColor,
                                      ),
                                    ),

                                    SizedBox(
                                      width: columnWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SettingsSectionHeader(
                                            title:
                                                'export_import_settings_title'
                                                    .tr(),
                                            icon: Icons.import_export,
                                            isDarkMode: themeData.isDarkMode,
                                            accentColor: themeData.accentColor,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: themeData.isDarkMode
                                                  ? MainScreenColors
                                                        .darkSurfaceColor
                                                  : MainScreenColors
                                                        .lightSurfaceColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: themeData.isDarkMode
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                width: 1,
                                              ),
                                            ),
                                            child: SettingsItem(
                                              icon: Icons.import_export,
                                              title:
                                                  'export_import_settings_title'
                                                      .tr(),
                                              trailing: Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ExportImportSettingsScreen(),
                                                  ),
                                                );
                                              },
                                              isDarkMode: themeData.isDarkMode,
                                              accentColor:
                                                  themeData.accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(
                                      width: columnWidth,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SettingsSectionHeader(
                                            title: 'about_settings'.tr(),
                                            icon: Icons.info,
                                            isDarkMode: themeData.isDarkMode,
                                            accentColor: themeData.accentColor,
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: themeData.isDarkMode
                                                  ? MainScreenColors
                                                        .darkSurfaceColor
                                                  : MainScreenColors
                                                        .lightSurfaceColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: themeData.isDarkMode
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.06,
                                                      ),
                                                width: 1,
                                              ),
                                            ),
                                            child: SettingsItem(
                                              icon: Icons.info,
                                              title: 'about_auralis_card_title'
                                                  .tr(),
                                              trailing: Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const AboutSettingsScreen(),
                                                  ),
                                                );
                                              },
                                              isDarkMode: themeData.isDarkMode,
                                              accentColor:
                                                  themeData.accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: AppDimens.spacingXxxl),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    if (AppDimens.isMobile(context) && hasPlayer)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppDimens.radiusMd),
                          ),
                        ),
                        child: SizedBox(
                          height: AppDimens.miniPlayerHeight * navIconScale,
                          child: PlayerUI(
                            showFullScreen: false,
                            isEmbedded: true,
                            onMinimize: () {},
                            onExpand: () => _showFullPlayerBottomSheet(context),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFullPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const FullPlayerScreen(),
    );
  }

  Widget _buildUpdateBanner(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    final updateInfo = otaProvider.updateInfo!;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.spacingXl),
      padding: EdgeInsets.all(AppDimens.paddingLg),
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: accentColor,
          width: AppDimens.borderWidthThick,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppDimens.paddingSm),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Icon(
                  Icons.system_update,
                  color: accentColor,
                  size: AppDimens.iconMd,
                ),
              ),
              SizedBox(width: AppDimens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ota_update_available'.tr(),
                      style: AppTextStyles.subtitle(
                        isDarkMode: isDarkMode,
                      ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                    ),
                    Text(
                      'ota_version_and_size'.tr(
                        args: [updateInfo.latestVersion, updateInfo.size],
                      ),
                      style: AppTextStyles.caption(isDarkMode: isDarkMode)
                          .copyWith(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OTAScreen()),
                  );
                },
                child: Text(
                  'view_button'.tr(),
                  style: AppTextStyles.bodyMd(
                    isDarkMode: isDarkMode,
                    color: accentColor,
                  ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                ),
              ),
            ],
          ),
          if (updateInfo.updateLog.isNotEmpty) ...[
            SizedBox(height: AppDimens.spacingMd),
            Text(
              updateInfo.updateLog.first,
              style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.8),
                height: AppTextStyles.lineHeightBody,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppUpdatesSection(
    BuildContext context,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.paddingXs,
            AppDimens.spacingXxl,
            AppDimens.paddingXs,
            AppDimens.spacingMd,
          ),
          child: Row(
            children: [
              Icon(
                Icons.system_update,
                color: accentColor,
                size: AppDimens.iconMdLg,
              ),
              const SizedBox(width: 8),
              Text(
                'app_updates'.tr(),
                style: AppTextStyles.titleSm(
                  isDarkMode: isDarkMode,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        Consumer<OTAProvider>(
          builder: (context, otaProvider, child) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? MainScreenColors.darkSurfaceColor
                    : MainScreenColors.lightSurfaceColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                  width: AppDimens.borderWidthThin,
                ),
              ),
              child: SettingsItem(
                icon: Icons.system_update,
                title: otaProvider.status == OTAStatus.updateAvailable
                    ? 'update_available_item_title'.tr(
                        args: [otaProvider.updateInfo?.latestVersion ?? ''],
                      )
                    : 'ota_check_for_updates'.tr(),
                trailing: otaProvider.status == OTAStatus.checking
                    ? SizedBox(
                        width: AppDimens.iconXs,
                        height: AppDimens.iconXs,
                        child: CircularProgressIndicator(
                          strokeWidth: AppDimens.progressStroke,
                          color: accentColor,
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios,
                        size: AppDimens.iconXs,
                        color: Colors.grey,
                      ),
                onTap: otaProvider.status == OTAStatus.checking
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OTAScreen(),
                          ),
                        );
                      },
                isDarkMode: isDarkMode,
                accentColor: accentColor,
              ),
            );
          },
        ),
      ],
    );
  }

  // String _getUpdateSubtitle(OTAProvider otaProvider) {
  //   switch (otaProvider.status) {
  //     case OTAStatus.checking:
  //       return 'ota_checking_for_updates'.tr();
  //     case OTAStatus.updateAvailable:
  //       return 'update_available_subtitle'.tr(
  //         args: [otaProvider.updateInfo?.latestVersion ?? ''],
  //       );
  //     case OTAStatus.noUpdate:
  //       return 'you_are_up_to_date_subtitle'.tr();
  //     case OTAStatus.error:
  //       return 'update_check_failed_subtitle'.tr();
  //     default:
  //       return 'tap_to_check_for_updates_subtitle'.tr();
  //   }
  // }
}
