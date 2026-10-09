import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

class ThemeSetupScreen extends StatefulWidget {
  final VoidCallback onNext;

  const ThemeSetupScreen({Key? key, required this.onNext}) : super(key: key);

  @override
  State<ThemeSetupScreen> createState() => _ThemeSetupScreenState();
}

class _ThemeSetupScreenState extends State<ThemeSetupScreen> {
  String _selectedTheme = 'Dark';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MainScreenColors.getBackgroundColor(isDarkMode),
            MainScreenColors.getSurfaceColor(isDarkMode),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth > 600;
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                        isLarge ? AppDimens.spacing5Xl : AppDimens.paddingXl,
                      ),
                      child: isLarge
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'choose_your_theme'.tr(),
                                      style: AppTextStyles.hero(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                    SizedBox(height: AppDimens.spacingLg),
                                    Text(
                                      'select_theme'.tr(),
                                      style: AppTextStyles.headingLg(
                                        isDarkMode: isDarkMode,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppDimens.spacing5Xl),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: _buildThemeOption(
                                        'Light',
                                        'bright_and_clean_interface'.tr(),
                                        Icons.light_mode,
                                        size,
                                        isLarge: isLarge,
                                      ),
                                    ),
                                    SizedBox(width: AppDimens.spacingXxxl),
                                    Flexible(
                                      child: _buildThemeOption(
                                        'Dark',
                                        'easy_on_the_eyes'.tr(),
                                        Icons.dark_mode,
                                        size,
                                        isLarge: isLarge,
                                      ),
                                    ),
                                    SizedBox(width: AppDimens.spacingXxxl),
                                    Flexible(
                                      child: _buildThemeOption(
                                        'System Default',
                                        'system_default_theme'.tr(),
                                        Icons.settings_suggest,
                                        size,
                                        isLarge: isLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: AppDimens.spacingXxxl),
                                Text(
                                  'choose_your_theme'.tr(),
                                  style: AppTextStyles.headingLg(
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                                SizedBox(height: AppDimens.spacingLg),
                                Text(
                                  'select_theme'.tr(),
                                  style: AppTextStyles.subtitle(
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                                SizedBox(height: AppDimens.spacing4Xl),
                                _buildThemeOption(
                                  'Light',
                                  'bright_and_clean_interface'.tr(),
                                  Icons.light_mode,
                                  size,
                                ),
                                SizedBox(height: AppDimens.spacingXxl),
                                _buildThemeOption(
                                  'Dark',
                                  'easy_on_the_eyes'.tr(),
                                  Icons.dark_mode,
                                  size,
                                ),
                                SizedBox(height: AppDimens.spacingXxl),
                                _buildThemeOption(
                                  'System Default',
                                  'system_default_theme'.tr(),
                                  Icons.settings_suggest,
                                  size,
                                ),
                              ],
                            ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(
                      isLarge ? AppDimens.spacing5Xl : AppDimens.paddingXl,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final settingsProvider = Provider.of<SettingsProvider>(
                          context,
                          listen: false,
                        );
                        settingsProvider.theme = _selectedTheme;
                        widget.onNext();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        minimumSize: Size(
                          double.infinity,
                          isLarge
                              ? AppDimens.buttonSizeLg
                              : AppDimens.buttonSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusXl,
                          ),
                        ),
                        elevation: AppDimens.elevationHigh,
                        shadowColor: const Color(
                          0xFF6C63FF,
                        ).withValues(alpha: 0.5),
                      ),
                      child: Text(
                        'continue'.tr(),
                        style: isLarge
                            ? AppTextStyles.titleLg(
                                isDarkMode: isDarkMode,
                              ).copyWith(color: Colors.white)
                            : AppTextStyles.titleSm(
                                isDarkMode: isDarkMode,
                              ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String theme,
    String description,
    IconData icon,
    Size size, {
    bool isLarge = false,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final isSelected = _selectedTheme == theme;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTheme = theme);
        final settingsProvider = Provider.of<SettingsProvider>(
          context,
          listen: false,
        );
        settingsProvider.theme = theme;
      },
      child: AnimatedContainer(
        duration: AppDimens.animDefault,
        padding: EdgeInsets.all(AppDimens.paddingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? MainScreenColors.getPrimaryColor(isDarkMode)
              : MainScreenColors.getSurfaceColor(isDarkMode),
          borderRadius: BorderRadius.circular(
            isLarge ? AppDimens.radiusLg : AppDimens.radiusXxl,
          ),
          border: Border.all(
            color: isSelected
                ? MainScreenColors.getPrimaryColor(isDarkMode)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MainScreenColors.getPrimaryColor(
                      isDarkMode,
                    ).withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppDimens.paddingSm),
              decoration: BoxDecoration(
                color: isSelected && !isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : isSelected
                    ? MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.2)
                    : MainScreenColors.getSurfaceColor(isDarkMode),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(
                icon,
                color: isSelected && !isDarkMode
                    ? Colors.white
                    : MainScreenColors.getTextColor(isDarkMode),
                size: AppDimens.iconMd,
              ),
            ),
            SizedBox(
              width: isLarge ? AppDimens.spacingSm : AppDimens.spacingMdLg,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme,
                    style: AppTextStyles.titleSm(isDarkMode: isDarkMode)
                        .copyWith(
                          color: isSelected && !isDarkMode
                              ? Colors.white
                              : MainScreenColors.getTextColor(isDarkMode),
                          fontWeight: AppTextStyles.weightBold,
                        ),
                  ),
                  SizedBox(
                    height: isLarge
                        ? AppDimens.spacingXxs
                        : AppDimens.spacingXs,
                  ),
                  Text(
                    description,
                    style: AppTextStyles.caption(isDarkMode: isDarkMode)
                        .copyWith(
                          color: isSelected && !isDarkMode
                              ? Colors.white70
                              : (isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: isSelected
                  ? (isSelected && !isDarkMode
                        ? Colors.white
                        : MainScreenColors.getTextColor(isDarkMode))
                  : Colors.transparent,
              size: AppDimens.iconMd,
            ),
          ],
        ),
      ),
    );
  }
}
