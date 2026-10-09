import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../shared/animations/animation_1.dart';
import '../../../../shared/animations/animation_2.dart';
import '../../../../shared/animations/animation_3.dart';
import '../../../../shared/animations/animation_4.dart';
import '../../../../shared/animations/animation_5.dart';

class AnimationSelectorScreen extends StatefulWidget {
  const AnimationSelectorScreen({Key? key}) : super(key: key);

  @override
  State<AnimationSelectorScreen> createState() =>
      _AnimationSelectorScreenState();
}

class _AnimationSelectorScreenState extends State<AnimationSelectorScreen> {
  String currentAnimation = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      setState(() {
        currentAnimation = settingsProvider.animationType;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
      SettingsProvider,
      ({
        bool isDarkMode,
        Color accentColor,
        String animationType,
        Color playerServiceBackgroundColor,
      })
    >(
      selector: (context, settingsProvider) {
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final playerService = playerProvider.playerService;
        return (
          isDarkMode: settingsProvider.themeMode == ThemeMode.dark,
          accentColor: settingsProvider.accentColor,
          animationType: settingsProvider.animationType,
          playerServiceBackgroundColor:
              playerService.backgroundColorNotifier.value,
        );
      },
      builder: (context, themeData, child) {
        if (currentAnimation.isEmpty) {
          currentAnimation = themeData.animationType;
        }

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
                'animations'.tr(),
                style: AppTextStyles.appBarTitle(
                  isDarkMode: themeData.isDarkMode,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: MainScreenColors.getTextColor(themeData.isDarkMode),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: false,
              actions: [
                Container(
                  margin: EdgeInsets.only(right: AppDimens.paddingLg),
                  child: TextButton.icon(
                    onPressed: () {
                      Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).animationType = currentAnimation;
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.check,
                      color: themeData.accentColor,
                      size: AppDimens.iconMd,
                    ),
                    label: Text(
                      'save'.tr(),
                      style: AppTextStyles.titleSm(
                        isDarkMode: themeData.isDarkMode,
                        color: themeData.accentColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: themeData.accentColor.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusXxl,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.paddingLg,
                        vertical: AppDimens.paddingSm,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(bottom: AppDimens.spacingXl),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 600
                            ? AppDimens.spacingSmMd
                            : AppDimens.paddingLg,
                      ),
                      height:
                          MediaQuery.of(context).size.height *
                          (MediaQuery.of(context).size.width < 600
                              ? 0.20
                              : 0.28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: AppDimens.elevationHigh,
                            offset: Offset(0, AppDimens.spacingS),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusXxl,
                        ),
                        child: _buildCurrentAnimation(themeData),
                      ),
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 600
                            ? AppDimens.paddingMd
                            : AppDimens.paddingXl,
                      ),
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 600
                            ? AppDimens.paddingMd
                            : AppDimens.spacingMdLg,
                      ),
                      decoration: BoxDecoration(
                        color: themeData.isDarkMode
                            ? MainScreenColors.darkSurfaceColor
                            : MainScreenColors.lightSurfaceColor,
                        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                        border: Border.all(
                          color: themeData.accentColor.withValues(alpha: 0.15),
                          width: AppDimens.borderWidthThin,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentAnimation,
                            style: MediaQuery.of(context).size.width < 600
                                ? AppTextStyles.subtitle(
                                    isDarkMode: themeData.isDarkMode,
                                  )
                                : AppTextStyles.titleSm(
                                    isDarkMode: themeData.isDarkMode,
                                  ),
                          ),
                          SizedBox(height: AppDimens.spacingS),
                          Text(
                            _getAnimationDescription(currentAnimation),
                            style:
                                (MediaQuery.of(context).size.width < 600
                                        ? AppTextStyles.caption(
                                            isDarkMode: themeData.isDarkMode,
                                          )
                                        : AppTextStyles.body2(
                                            isDarkMode: themeData.isDarkMode,
                                          ))
                                    .copyWith(
                                      color: MainScreenColors.getTextColor(
                                        themeData.isDarkMode,
                                      ).withValues(alpha: 0.7),
                                    ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: MediaQuery.of(context).size.width < 600
                          ? AppDimens.spacingLg
                          : AppDimens.spacingXl,
                    ),

                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 600
                            ? AppDimens.paddingMd
                            : AppDimens.paddingXl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'choose_animation'.tr(),
                            style: MediaQuery.of(context).size.width < 600
                                ? AppTextStyles.bodyLg(
                                    isDarkMode: themeData.isDarkMode,
                                  )
                                : AppTextStyles.subtitle(
                                    isDarkMode: themeData.isDarkMode,
                                  ),
                          ),
                          SizedBox(height: AppDimens.spacingMd),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const animationOptions = [
                                'Default',
                                'Animation 1',
                                'Animation 2',
                                'Animation 3',
                                'Animation 4',
                                'Animation 5',
                                'static',
                              ];
                              final double itemWidth =
                                  140; // Minimum width per animation option
                              final int crossAxisCount =
                                  (constraints.maxWidth / itemWidth)
                                      .floor()
                                      .clamp(1, 6);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing:
                                          MediaQuery.of(context).size.width <
                                              600
                                          ? AppDimens.spacingSm
                                          : AppDimens.spacingSmMd,
                                      mainAxisSpacing:
                                          MediaQuery.of(context).size.width <
                                              600
                                          ? AppDimens.spacingSm
                                          : AppDimens.spacingSmMd,
                                      childAspectRatio:
                                          MediaQuery.of(context).size.width <
                                              600
                                          ? 3.0
                                          : 2.8,
                                    ),
                                itemCount: animationOptions.length,
                                itemBuilder: (context, index) {
                                  final animationName = animationOptions[index];
                                  final isSelected =
                                      currentAnimation == animationName;

                                  return _buildAnimationOption(
                                    animationName,
                                    isSelected,
                                    themeData,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.width < 600
                          ? AppDimens.spacingLg
                          : AppDimens.spacingXl,
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

  Widget _buildCurrentAnimation(
    ({
      bool isDarkMode,
      Color accentColor,
      String animationType,
      Color playerServiceBackgroundColor,
    })
    themeData,
  ) {
    final backgroundColor = themeData.playerServiceBackgroundColor;
    final accentColor = themeData.accentColor;
    switch (currentAnimation) {
      case 'Default':
        return Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8)),
        );
      case 'static':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.9),
                backgroundColor,
                backgroundColor.withValues(alpha: 0.6),
                accentColor.withValues(alpha: 0.2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
      case 'Animation 1':
        return Animation1(
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          isAnimating: true,
        );
      case 'Animation 2':
        return Animation2(
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          isAnimating: true,
        );
      case 'Animation 3':
        return Animation3(
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          isAnimating: true,
        );
      case 'Animation 4':
        return Animation4(
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          isAnimating: true,
        );
      case 'Animation 5':
        return Animation5(
          backgroundColor: backgroundColor,
          accentColor: accentColor,
          isAnimating: true,
        );
      default:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundColor, Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        );
    }
  }

  Widget _buildAnimationOption(
    String animationName,
    bool isSelected,
    themeData,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          currentAnimation = animationName;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? themeData.accentColor.withValues(alpha: 0.15)
              : (themeData.isDarkMode
                    ? MainScreenColors.darkSurfaceColor
                    : MainScreenColors.lightSurfaceColor),
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color: isSelected
                ? themeData.accentColor
                : MainScreenColors.getTextColor(
                    themeData.isDarkMode,
                  ).withValues(alpha: 0.1),
            width: isSelected
                ? AppDimens.borderWidthThick
                : AppDimens.borderWidthThin,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeData.accentColor.withValues(alpha: 0.3),
                    blurRadius: AppDimens.elevationHigh,
                    offset: Offset(0, AppDimens.spacingXs),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  margin: EdgeInsets.only(right: AppDimens.spacingSm),
                  padding: EdgeInsets.all(AppDimens.spacingXs),
                  decoration: BoxDecoration(
                    color: themeData.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: AppDimens.iconXs,
                  ),
                ),
              Text(
                animationName,
                style: AppTextStyles.subtitle(isDarkMode: themeData.isDarkMode)
                    .copyWith(
                      color: isSelected
                          ? themeData.accentColor
                          : MainScreenColors.getTextColor(themeData.isDarkMode),
                      fontWeight: isSelected
                          ? AppTextStyles.weightSemiBold
                          : AppTextStyles.weightMedium,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAnimationDescription(String animationType) {
    switch (animationType) {
      case 'Default':
        return 'static_animation_description'.tr();
      case 'Animation 1':
        return 'animation_1_description'.tr();
      case 'Animation 2':
        return 'animation_2_description'.tr();
      case 'Animation 3':
        return 'animation_3_description'.tr();
      case 'Animation 4':
        return 'animation_4_description'.tr();
      case 'Animation 5':
        return 'animation_5_description'.tr();
      case 'static':
        return 'static_animation_description'.tr();
      default:
        return 'A beautiful animation effect for your music player.';
    }
  }
}
