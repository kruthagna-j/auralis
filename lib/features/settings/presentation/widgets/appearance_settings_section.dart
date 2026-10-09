import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dynamic_color/dynamic_color.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import 'settings_item.dart';
import '../screens/animation_selector_screen.dart';

class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({Key? key}) : super(key: key);

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
              title: 'appearance_settings'.tr(),
              icon: Icons.color_lens,
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
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      return SettingsItem(
                        icon: Icons.brightness_6,
                        title: 'theme_card_title'.tr(),
                        trailing: _buildThemeSelector(
                          context,
                          settingsProvider,
                          themeData.accentColor,
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
                      return SettingsItem(
                        icon: Icons.palette,
                        title: 'accent_color_card_title'.tr(),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: settingsProvider.adaptiveColorEnabled
                                  ? 0.5
                                  : 1.0,
                              child: Container(
                                width: AppDimens.iconMd,
                                height: AppDimens.iconMd,
                                decoration: BoxDecoration(
                                  color: settingsProvider.accentColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: AppDimens.borderWidthThin,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppDimens.spacingSm),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: AppDimens.iconXs,
                              color: settingsProvider.adaptiveColorEnabled
                                  ? Colors.grey.withValues(alpha: 0.6)
                                  : Colors.grey,
                            ),
                          ],
                        ),
                        onTap: settingsProvider.adaptiveColorEnabled
                            ? null
                            : () => _showColorPickerDialog(
                                context,
                                settingsProvider,
                                themeData.isDarkMode,
                              ),
                        isDarkMode: themeData.isDarkMode,
                        accentColor: themeData.accentColor,
                      );
                    },
                  ),

                  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
                    _AdaptiveColorSettingsItem(
                      isDarkMode: themeData.isDarkMode,
                      accentColor: themeData.accentColor,
                      platform: TargetPlatform.android,
                    ),
                  if (Platform.isWindows)
                    _AdaptiveColorSettingsItem(
                      isDarkMode: themeData.isDarkMode,
                      accentColor: themeData.accentColor,
                      platform: TargetPlatform.windows,
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
                        icon: Icons.movie,
                        title: 'animation_type'.tr(),
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
                                  const AnimationSelectorScreen(),
                            ),
                          );
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

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsProvider settingsProvider,
    Color accentColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildThemeButton(
          context: context,
          label: 'Light',
          selected: settingsProvider.theme == 'Light',
          onTap: () => settingsProvider.theme = 'Light',
          accentColor: accentColor,
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 360 ? 2 : 4),
        _buildThemeButton(
          context: context,
          label: 'Dark',
          selected: settingsProvider.theme == 'Dark',
          onTap: () => settingsProvider.theme = 'Dark',
          accentColor: accentColor,
        ),
        SizedBox(width: MediaQuery.of(context).size.width < 360 ? 2 : 4),
        _buildThemeButton(
          context: context,
          label: 'Auto',
          selected: settingsProvider.theme == 'System Default',
          onTap: () => settingsProvider.theme = 'System Default',
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildThemeButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    final bool isSmall = AppDimens.isSmallMobile(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmall ? AppDimens.paddingXs : AppDimens.paddingSm,
          horizontal: isSmall ? AppDimens.paddingSm : AppDimens.paddingMd,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            isSmall ? AppDimens.radiusSm : AppDimens.radiusMd,
          ),
          border: Border.all(
            color: selected ? accentColor : Colors.grey.withValues(alpha: 0.3),
            width: AppDimens.borderWidthThin,
          ),
        ),
        child: Text(
          label,
          style:
              AppTextStyles.caption(
                isDarkMode: false,
                color: selected ? accentColor : Colors.grey,
              ).copyWith(
                fontWeight: selected
                    ? AppTextStyles.weightSemiBold
                    : AppTextStyles.weightRegular,
              ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    SettingsProvider settingsProvider,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? MainScreenColors.darkSurfaceColor
              : MainScreenColors.lightSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          title: Text(
            'choose_accent_color_dialog_title'.tr(),
            style: AppTextStyles.heading(isDarkMode: isDarkMode),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth =
                    AppDimens.thumbnailLarge; // Minimum width per color item
                final int crossAxisCount = (constraints.maxWidth / itemWidth)
                    .floor()
                    .clamp(2, 8);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppDimens.spacingLg,
                    mainAxisSpacing: AppDimens.spacingLg,
                  ),
                  itemCount: MainScreenColors.accentColors.length,
                  itemBuilder: (context, index) {
                    final color = MainScreenColors.accentColors[index];
                    return GestureDetector(
                      onTap: () {
                        settingsProvider.accentColor = color;
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          border: Border.all(
                            color: settingsProvider.accentColor == color
                                ? MainScreenColors.getTextColor(isDarkMode)
                                : Colors.transparent,
                            width: AppDimens.borderWidthThick,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _AdaptiveColorSettingsItem extends StatefulWidget {
  final bool isDarkMode;
  final Color accentColor;
  final TargetPlatform platform;

  const _AdaptiveColorSettingsItem({
    Key? key,
    required this.isDarkMode,
    required this.accentColor,
    required this.platform,
  }) : super(key: key);

  @override
  State<_AdaptiveColorSettingsItem> createState() =>
      _AdaptiveColorSettingsItemState();
}

class _AdaptiveColorSettingsItemState
    extends State<_AdaptiveColorSettingsItem> {
  Future<dynamic>? _adaptiveColorFuture;

  @override
  void initState() {
    super.initState();
    _adaptiveColorFuture = widget.platform == TargetPlatform.windows
        ? DynamicColorPlugin.getAccentColor()
        : DynamicColorPlugin.getCorePalette();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return FutureBuilder<dynamic>(
          future: _adaptiveColorFuture,
          builder: (context, snapshot) {
            final dynamic colorData = snapshot.data;
            final bool available =
                snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                colorData != null;

            if (!available) return const SizedBox.shrink();

            return SettingsToggleItem(
              icon: Icons.auto_awesome,
              title: 'adaptive_color_title'.tr(),
              value: settingsProvider.adaptiveColorEnabled,
              onChanged: (value) async {
                if (value) {
                  Color? dynamicColor;
                  if (widget.platform == TargetPlatform.windows) {
                    dynamicColor = colorData as Color?;
                  } else {
                    final core = colorData;
                    try {
                      final int? primaryTonal = core.primary.get(40);
                      if (primaryTonal != null)
                        dynamicColor = Color(primaryTonal);
                    } catch (_) {}
                  }
                  await settingsProvider.setAdaptiveColorEnabled(
                    true,
                    dynamicColor: dynamicColor,
                  );
                } else {
                  await settingsProvider.setAdaptiveColorEnabled(false);
                }
              },
              isDarkMode: widget.isDarkMode,
              accentColor: widget.accentColor,
            );
          },
        );
      },
    );
  }
}
