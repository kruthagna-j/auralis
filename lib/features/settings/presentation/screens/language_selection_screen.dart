import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final VoidCallback? onSelected;
  final bool isOnboardingFlow;

  LanguageSelectionScreen({
    Key? key,
    this.onSelected,
    this.isOnboardingFlow = false,
  }) : super(key: key);

  final List<Map<String, String>> languages = [
    {'name': 'English', 'flag': '🇺🇸'},
    {'name': 'Hindi', 'flag': '🇮🇳'},
    {'name': 'Spanish', 'flag': '🇪🇸'},
    {'name': 'French', 'flag': '🇫🇷'},
    {'name': 'German', 'flag': '🇩🇪'},
    {'name': 'Russian', 'flag': '🇷🇺'},
    {'name': 'Ukrainian', 'flag': '🇺🇦'},
    {'name': 'Bengali', 'flag': '🇮🇳'},
    {'name': 'Arabic', 'flag': '🇸🇦'},
    {'name': 'Japanese', 'flag': '🇯🇵'},
    {'name': 'Chinese', 'flag': '🇨🇳'},
    {'name': 'Urdu', 'flag': '🇵🇰'},
    {'name': 'Telugu', 'flag': '🇮🇳'},
    {'name': 'Tamil', 'flag': '🇮🇳'},
    {'name': 'Marathi', 'flag': '🇮🇳'},
    {'name': 'Gujarati', 'flag': '🇮🇳'},
    {'name': 'Kannada', 'flag': '🇮🇳'},
    {'name': 'Korean', 'flag': '🇰🇷'},
    {'name': 'Portuguese', 'flag': '🇵🇹'},
    {'name': 'Indonesian', 'flag': '🇮🇩'},
    {'name': 'Turkish', 'flag': '🇹🇷'},
    {'name': 'Vietnamese', 'flag': '🇻🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.transparent
              : MainScreenColors.getSurfaceColor(false),
          elevation: 0,
          title: Text(
            'Select Language',
            style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
          ),
          leading: isOnboardingFlow
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: MainScreenColors.getTextColor(isDarkMode),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
        body: Padding(
          padding: EdgeInsets.all(AppDimens.paddingLg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = AppDimens.shimmerGridItem;
              final int crossAxisCount = (constraints.maxWidth / itemWidth)
                  .floor()
                  .clamp(1, 5);
              return GridView.builder(
                itemCount: languages.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppDimens.spacingMd,
                  mainAxisSpacing: AppDimens.spacingMd,
                  childAspectRatio:
                      AppDimens.buttonWidthMedium / AppDimens.buttonHeightLarge,
                ),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final selected = settingsProvider.language == lang['name'];
                  return GestureDetector(
                    onTap: () {
                      settingsProvider.language = lang['name']!;
                      if (!isOnboardingFlow) {
                        if (onSelected != null) {
                          onSelected!();
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor.withValues(
                                alpha: AppDimens.opacityLight,
                              )
                            : (isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(
                          color: selected ? accentColor : Colors.transparent,
                          width: AppDimens.borderWidthThick,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: AppDimens.paddingSm,
                              right: AppDimens.paddingMd,
                            ),
                            child: Text(
                              lang['flag']!,
                              style: AppTextStyles.headingBase(),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: AppTextStyles.subtitle(
                                isDarkMode: isDarkMode,
                                color: selected
                                    ? accentColor
                                    : MainScreenColors.getTextColor(isDarkMode),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selected)
                            Padding(
                              padding: EdgeInsets.only(
                                right: AppDimens.spacingXs,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: accentColor,
                                size: AppDimens.iconMdLg,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: isOnboardingFlow
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingLg,
                    vertical: AppDimens.paddingMd,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: accentColor,
                              width: AppDimens.dividerHeight,
                            ),
                            minimumSize: const Size(
                              double.infinity,
                              AppDimens.buttonSizeDefault,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: AppTextStyles.subtitle(
                              isDarkMode: isDarkMode,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppDimens.spacingMd),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onSelected,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            minimumSize: const Size(
                              double.infinity,
                              AppDimens.buttonSizeDefault,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: AppTextStyles.subtitle(
                              isDarkMode: isDarkMode,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
