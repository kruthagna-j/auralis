import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({Key? key}) : super(key: key);

  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static const String _baseUrl =
      'https://raw.githubusercontent.com/kruthagna-j/auralis-app/main/docs/changelogs';

  Future<Directory> _changelogDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}${Platform.pathSeparator}auralis${Platform.pathSeparator}changelogs',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _fetchAndCacheChangelog(String filename) async {
    final dir = await _changelogDir();
    final file = File('${dir.path}${Platform.pathSeparator}$filename');

    try {
      final response = await http.get(Uri.parse('$_baseUrl/$filename'));
      if (response.statusCode == 200) {
        await file.writeAsString(response.body);
        return response.body;
      }
    } catch (_) {}

    if (await file.exists()) return file.readAsString();
    return '';
  }

  Future<List<Map<String, dynamic>>> _fetchVersionList() async {
    final dir = await _changelogDir();
    final cacheFile = File(
      '${dir.path}${Platform.pathSeparator}changelog.json',
    );

    String? jsonStr;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/changelog.json'));
      if (response.statusCode == 200) {
        jsonStr = response.body;
        await cacheFile.writeAsString(jsonStr);
      }
    } catch (_) {}

    jsonStr ??= await cacheFile.exists()
        ? await cacheFile.readAsString()
        : null;
    if (jsonStr == null) return [];

    final data = jsonDecode(jsonStr);
    return List<Map<String, dynamic>>.from(data['versions'] ?? []);
  }

  void _showReleaseNotes(
    BuildContext context,
    bool isDarkMode,
    Color accentColor,
  ) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final versions = await _fetchVersionList();
    if (!context.mounted) return;

    int initialIndex = versions.indexWhere(
      (v) => v['version'] == currentVersion,
    );
    if (initialIndex < 0) initialIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReleaseNotesSheet(
        versions: versions,
        initialIndex: initialIndex,
        currentVersion: currentVersion,
        isDarkMode: isDarkMode,
        accentColor: accentColor,
        fetchChangelog: _fetchAndCacheChangelog,
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildGradientCard({
    required Widget child,
    required bool isDarkMode,
    required Color accentColor,
    double? height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  accentColor.withValues(alpha: 0.08),
                  accentColor.withValues(alpha: 0.03),
                ]
              : [
                  accentColor.withValues(alpha: 0.05),
                  accentColor.withValues(alpha: 0.02),
                ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        border: Border.all(
          color: accentColor.withValues(alpha: AppDimens.opacityLight),
          width: AppDimens.borderWidthThin,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: AppDimens.paddingMd,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppDimens.paddingXl),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: AppDimens.opacitySubtle)
                : Colors.black.withValues(alpha: AppDimens.opacitySubtle),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingMd),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: AppDimens.opacityOverlay,
                    ),
                    blurRadius: AppDimens.spacingSm,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: AppDimens.iconLg),
            ),
            SizedBox(width: AppDimens.spacingLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                  ),
                  SizedBox(height: AppDimens.spacingXs),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(isDarkMode: isDarkMode)
                        .copyWith(
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: AppDimens.opacityMid),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: accentColor,
              size: AppDimens.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimens.paddingXl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.15),
                accentColor.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
            border: Border.all(
              color: accentColor.withValues(alpha: AppDimens.opacityMedium),
              width: AppDimens.borderWidthThick,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: AppDimens.iconXl),
              ),
              SizedBox(height: AppDimens.spacingMd),
              Text(
                label,
                style: AppTextStyles.body2(
                  isDarkMode: isDarkMode,
                ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= AppDimens.breakpointDesktop;
        final isTablet =
            screenWidth >= AppDimens.breakpointTabletShort &&
            screenWidth < AppDimens.breakpointDesktop;
        final isMobile = !isDesktop && !isTablet;

        final horizontalPadding = isDesktop
            ? AppDimens.spacing4Xl
            : isTablet
            ? AppDimens.spacingXxl
            : AppDimens.paddingXl;
        final maxContentWidth = isDesktop
            ? AppDimens.maxContentWidth
            : double.infinity;
        final logoSize = isDesktop
            ? 120.0
            : isTablet
            ? 110.0
            : 100.0;
        final expandedHeight = isDesktop
            ? 330.0
            : isTablet
            ? 310.0
            : 320.0;

        return SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: isDarkMode
                ? MainScreenColors.darkBackgroundColor
                : MainScreenColors.lightBackgroundColor,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: expandedHeight,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDarkMode
                      ? MainScreenColors.darkBackgroundColor
                      : MainScreenColors.lightBackgroundColor,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MainScreenColors.getTextColor(isDarkMode),
                      size: AppDimens.iconMd,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor.withValues(
                              alpha: AppDimens.opacityMedium,
                            ),
                            isDarkMode
                                ? MainScreenColors.darkBackgroundColor
                                : MainScreenColors.lightBackgroundColor,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: isMobile
                                    ? AppDimens.spacingXxl
                                    : AppDimens.spacing4Xl,
                              ),
                              Hero(
                                tag: 'app_logo',
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    AppDimens.paddingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accentColor,
                                        accentColor.withValues(
                                          alpha: AppDimens.opacityMid,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusAvatar,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: AppDimens.paddingXl,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusXxxl,
                                    ),
                                    child: Image.asset(
                                      'assets/default_artwork.png',
                                      width: logoSize,
                                      height: logoSize,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: AppDimens.paddingXl),
                              Text(
                                'app_name_auralis'.tr(),
                                style: isDesktop
                                    ? AppTextStyles.hero(isDarkMode: isDarkMode)
                                    : AppTextStyles.displayLg(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(letterSpacing: -0.5),
                              ),
                              SizedBox(height: AppDimens.spacingSm),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                ),
                                child: Text(
                                  'app_tagline'.tr(),
                                  textAlign: TextAlign.center,
                                  style:
                                      AppTextStyles.bodyLg(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        color:
                                            MainScreenColors.getTextColor(
                                              isDarkMode,
                                            ).withValues(
                                              alpha: AppDimens.opacityMuted,
                                            ),
                                      ),
                                ),
                              ),
                              SizedBox(height: AppDimens.spacingLg),
                              FutureBuilder<PackageInfo>(
                                future: getPackageInfo(),
                                builder: (context, snapshot) {
                                  final version =
                                      snapshot.data?.version ?? '...';
                                  final buildNumber =
                                      snapshot.data?.buildNumber ?? '';
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isMobile
                                          ? AppDimens.paddingXs
                                          : AppDimens.paddingSm,
                                      horizontal: AppDimens.paddingXl,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusXxl,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: AppDimens.opacityOverlay,
                                          ),
                                          blurRadius: AppDimens.spacingSm,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'v$version${buildNumber.isNotEmpty ? ' (${'build'.tr()} $buildNumber)' : ''}',
                                      style:
                                          (isMobile
                                                  ? AppTextStyles.caption()
                                                  : AppTextStyles.body2())
                                              .copyWith(
                                                color: Colors.white,
                                                fontWeight: AppTextStyles
                                                    .weightSemiBold,
                                              ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: AppDimens.spacingMd),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGradientCard(
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                            child: Padding(
                              padding: EdgeInsets.all(
                                isDesktop
                                    ? AppDimens.paddingXxl
                                    : AppDimens.paddingXl,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppDimens.paddingMd,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusLg,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      color: accentColor,
                                      size: AppDimens.iconLg,
                                    ),
                                  ),
                                  SizedBox(width: AppDimens.spacingLg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Open Source Project',
                                          style: AppTextStyles.subtitle(
                                            isDarkMode: isDarkMode,
                                          ),
                                        ),
                                        SizedBox(height: AppDimens.spacingXs),
                                        Text(
                                          'Made with ❤️ in India',
                                          style:
                                              AppTextStyles.body2(
                                                isDarkMode: isDarkMode,
                                              ).copyWith(
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      isDarkMode,
                                                    ).withValues(
                                                      alpha:
                                                          AppDimens.opacityMid,
                                                    ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimens.spacingXxxl),

                          Text(
                            'development'.tr(),
                            style: AppTextStyles.heading(
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          SizedBox(height: AppDimens.spacingLg),

                          _buildGradientCard(
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                            child: Padding(
                              padding: EdgeInsets.all(
                                isDesktop
                                    ? AppDimens.paddingXxl
                                    : AppDimens.paddingXl,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          AppDimens.paddingXs,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              accentColor,
                                              accentColor.withValues(
                                                alpha: AppDimens.opacityMid,
                                              ),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: CircleAvatar(
                                          radius: isDesktop
                                              ? 36
                                              : isTablet
                                              ? 32
                                              : 28,
                                          backgroundColor: isDarkMode
                                              ? MainScreenColors
                                                    .darkBackgroundColor
                                              : Colors.white,
                                          child: Icon(
                                            Icons.person_rounded,
                                            color: accentColor,
                                            size: isDesktop
                                                ? AppDimens.iconXxl
                                                : AppDimens.iconXxl,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppDimens.spacingLg),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Auralis',
                                              style: AppTextStyles.titleLg(
                                                isDarkMode: isDarkMode,
                                              ),
                                            ),
                                            SizedBox(
                                              height: AppDimens.spacingXs,
                                            ),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppDimens.paddingSm,
                                                      vertical:
                                                          AppDimens.spacingXxs,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: accentColor.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppDimens.radiusLg,
                                                      ),
                                                  border: Border.all(
                                                    color: accentColor
                                                        .withValues(alpha: 0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  'lead_developer'.tr(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                  style: AppTextStyles.finePrint()
                                                      .copyWith(
                                                        color: accentColor,
                                                        fontWeight:
                                                            AppTextStyles
                                                                .weightSemiBold,
                                                        letterSpacing: 0.1,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _launchURL(
                                          'https://github.com/kruthagna-j',
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDimens.radiusLg,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(
                                            isMobile
                                                ? AppDimens.paddingSm
                                                : AppDimens.paddingMd,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                accentColor,
                                                accentColor.withValues(
                                                  alpha: 0.8,
                                                ),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusLg,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withValues(
                                                  alpha:
                                                      AppDimens.opacityOverlay,
                                                ),
                                                blurRadius: AppDimens.spacingSm,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.code_rounded,
                                            color: Colors.white,
                                            size: isMobile
                                                ? AppDimens.iconSm
                                                : AppDimens.iconMd,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppDimens.paddingXl),
                                  Divider(
                                    color: isDarkMode
                                        ? Colors.white.withValues(
                                            alpha: AppDimens.opacityLight,
                                          )
                                        : Colors.black.withValues(
                                            alpha: AppDimens.opacityLight,
                                          ),
                                  ),
                                  SizedBox(height: AppDimens.spacingLg),
                                  Text(
                                    'about_dev'.tr(),
                                    style:
                                        AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          color:
                                              MainScreenColors.getTextColor(
                                                isDarkMode,
                                              ).withValues(
                                                alpha: AppDimens.opacityMuted,
                                              ),
                                          height:
                                              AppTextStyles.lineHeightRelaxed,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimens.spacingLg),

                          InkWell(
                            onTap: () => _launchURL(
                              'https://github.com/kruthagna-j/auralis-app/graphs/contributors',
                            ),
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusXl,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                AppDimens.paddingXl,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.black.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusXl,
                                ),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withValues(
                                          alpha: AppDimens.opacitySubtle,
                                        )
                                      : Colors.black.withValues(
                                          alpha: AppDimens.opacitySubtle,
                                        ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(
                                      AppDimens.paddingMd,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusLg,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.group_rounded,
                                      color: accentColor,
                                      size: AppDimens.iconLg,
                                    ),
                                  ),
                                  SizedBox(width: AppDimens.spacingLg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'team_members'.tr(),
                                          style: AppTextStyles.bodyLg(
                                            isDarkMode: isDarkMode,
                                          ),
                                        ),
                                        SizedBox(height: AppDimens.spacingXs),
                                        Text(
                                          'View all contributors',
                                          style:
                                              AppTextStyles.caption(
                                                isDarkMode: isDarkMode,
                                              ).copyWith(
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      isDarkMode,
                                                    ).withValues(
                                                      alpha:
                                                          AppDimens.opacityMid,
                                                    ),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: accentColor,
                                    size: AppDimens.iconSm,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimens.spacingXxxl),

                          Text(
                            'project'.tr(),
                            style: AppTextStyles.heading(
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          SizedBox(height: AppDimens.spacingLg),

                          _buildActionCard(
                            icon: Icons.code_rounded,
                            title: 'github_repository'.tr(),
                            subtitle: 'View source code',
                            onTap: () =>
                                _launchURL('https://github.com/kruthagna-j/auralis-app'),
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),

                          SizedBox(height: AppDimens.spacingMd),

                          _buildActionCard(
                            icon: Icons.volunteer_activism_rounded,
                            title: 'contribute'.tr(),
                            subtitle: 'help_improve_auralis'.tr(),
                            onTap: () => _launchURL(
                              'https://github.com/kruthagna-j/auralis-app/issues',
                            ),
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),

                          SizedBox(height: AppDimens.spacingMd),

                          _buildActionCard(
                            icon: Icons.new_releases_rounded,
                            title: 'release_notes'.tr(),
                            subtitle: 'see_release_notes_subtitle'.tr(),
                            onTap: () => _showReleaseNotes(
                              context,
                              isDarkMode,
                              accentColor,
                            ),
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),

                          SizedBox(height: AppDimens.spacingMd),

                          _buildActionCard(
                            icon: Icons.description_rounded,
                            title: 'open_source_licenses_card_title'.tr(),
                            subtitle: 'open_source_licenses_description'.tr(),
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: 'application_name_auralis'.tr(),
                              applicationLegalese: 'application_legalese_auralis'
                                  .tr(),
                            ),
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                          ),

                          SizedBox(height: AppDimens.spacingXxxl),

                          Text(
                            'contact_and_support'.tr(),
                            style: AppTextStyles.heading(
                              isDarkMode: isDarkMode,
                            ),
                          ),
                          SizedBox(height: AppDimens.spacingLg),

                          _buildGradientCard(
                            isDarkMode: isDarkMode,
                            accentColor: accentColor,
                            child: Padding(
                              padding: EdgeInsets.all(
                                isDesktop
                                    ? AppDimens.paddingXxl
                                    : AppDimens.paddingXxl,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.forum_rounded,
                                    color: accentColor,
                                    size: isDesktop
                                        ? AppDimens.iconStatus
                                        : AppDimens.iconHero,
                                  ),
                                  SizedBox(height: AppDimens.spacingLg),
                                  Text(
                                    'get_in_touch'.tr(),
                                    style: AppTextStyles.titleLg(
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                  SizedBox(height: AppDimens.spacingSm),
                                  Text(
                                    'connect_with_us_description'.tr(),
                                    textAlign: TextAlign.center,
                                    style:
                                        AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          color:
                                              MainScreenColors.getTextColor(
                                                isDarkMode,
                                              ).withValues(
                                                alpha: AppDimens.opacityMuted,
                                              ),
                                          height: AppTextStyles.lineHeightBody,
                                        ),
                                  ),
                                  SizedBox(height: AppDimens.spacingXxl),
                                  isDesktop
                                      ? Row(
                                          children: [
                                            _buildSocialButton(
                                              icon: Icons.telegram,
                                              label: 'Telegram',
                                              onTap: () => _launchURL(
                                                'https://github.com/kruthagna-j/auralis-app',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                            SizedBox(
                                              width: AppDimens.spacingMd,
                                            ),
                                            _buildSocialButton(
                                              icon: Icons.email_rounded,
                                              label: 'Email',
                                              onTap: () => _launchURL(
                                                'mailto:gravityappslabin@gmail.com',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                            SizedBox(
                                              width: AppDimens.spacingMd,
                                            ),
                                            _buildSocialButton(
                                              icon: Icons.language_rounded,
                                              label: 'Website',
                                              onTap: () => _launchURL(
                                                'https://github.com/kruthagna-j/auralis-app',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            _buildSocialButton(
                                              icon: Icons.telegram,
                                              label: 'Telegram',
                                              onTap: () => _launchURL(
                                                'https://github.com/kruthagna-j/auralis-app',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                            SizedBox(
                                              width: AppDimens.spacingMd,
                                            ),
                                            _buildSocialButton(
                                              icon: Icons.email_rounded,
                                              label: 'Email',
                                              onTap: () => _launchURL(
                                                'mailto:gravityappslabin@gmail.com',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                            SizedBox(
                                              width: AppDimens.spacingMd,
                                            ),
                                            _buildSocialButton(
                                              icon: Icons.language_rounded,
                                              label: 'Website',
                                              onTap: () => _launchURL(
                                                'https://github.com/kruthagna-j/auralis-app',
                                              ),
                                              accentColor: accentColor,
                                              isDarkMode: isDarkMode,
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: AppDimens.spacing4Xl),

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '© 2026 Auralis',
                                  style:
                                      AppTextStyles.caption(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        color:
                                            MainScreenColors.getTextColor(
                                              isDarkMode,
                                            ).withValues(
                                              alpha: AppDimens.opacitySemi,
                                            ),
                                      ),
                                ),
                                SizedBox(height: AppDimens.spacingSm),
                                Text(
                                  'Free • Open Source • Ad-Free',
                                  style:
                                      AppTextStyles.finePrint(
                                        isDarkMode: isDarkMode,
                                      ).copyWith(
                                        color: accentColor.withValues(
                                          alpha: AppDimens.opacityMuted,
                                        ),
                                        fontWeight: AppTextStyles.weightMedium,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: AppDimens.paddingXl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReleaseNotesSheet extends StatefulWidget {
  final List<Map<String, dynamic>> versions;
  final int initialIndex;
  final String currentVersion;
  final bool isDarkMode;
  final Color accentColor;
  final Future<String> Function(String filename) fetchChangelog;

  const _ReleaseNotesSheet({
    required this.versions,
    required this.initialIndex,
    required this.currentVersion,
    required this.isDarkMode,
    required this.accentColor,
    required this.fetchChangelog,
  });

  @override
  State<_ReleaseNotesSheet> createState() => _ReleaseNotesSheetState();
}

class _ReleaseNotesSheetState extends State<_ReleaseNotesSheet> {
  late int _selectedIndex;
  String _changelog = '';
  bool _loading = true;
  final Map<int, String> _cache = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadChangelog(_selectedIndex);
  }

  Future<void> _loadChangelog(int index) async {
    if (_cache.containsKey(index)) {
      setState(() {
        _changelog = _cache[index]!;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final version = widget.versions[index];
    final filename = version['file'] as String? ?? 'v${version['version']}.md';
    String content = await widget.fetchChangelog(filename);
    if (content.isEmpty) {
      content = 'release_notes_unavailable'.tr();
    }
    _cache[index] = content;
    if (mounted) {
      setState(() {
        _changelog = content;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final accentColor = widget.accentColor;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: AppDimens.sheetHeightFactor,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? MainScreenColors.darkBackgroundColor
              : MainScreenColors.lightBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusXxl),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: AppDimens.spacingMd),
            Container(
              width: AppDimens.dragHandleWidth,
              height: AppDimens.dragHandleHeight,
              decoration: BoxDecoration(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: AppDimens.opacityOverlay),
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingXl),
              child: Row(
                children: [
                  Icon(
                    Icons.new_releases_rounded,
                    color: accentColor,
                    size: AppDimens.iconXl,
                  ),
                  SizedBox(width: AppDimens.spacingMd),
                  Text(
                    'release_notes'.tr(),
                    style: AppTextStyles.titleLg(isDarkMode: isDarkMode),
                  ),
                ],
              ),
            ),
            if (widget.versions.isNotEmpty)
              SizedBox(
                height: AppDimens.buttonSizeLg,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingXl,
                  ),
                  itemCount: widget.versions.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: AppDimens.spacingSm),
                  itemBuilder: (context, index) {
                    final version = widget.versions[index];
                    final isSelected = index == _selectedIndex;
                    final isCurrent =
                        version['version'] == widget.currentVersion;
                    return FilterChip(
                      selected: isSelected,
                      label: Text(
                        'v${version['version']}${isCurrent ? ' (${'current'.tr()})' : ''}',
                        style:
                            AppTextStyles.caption(
                              isDarkMode: isDarkMode,
                              color: isSelected ? Colors.white : null,
                            ).copyWith(
                              fontWeight: isSelected
                                  ? AppTextStyles.weightSemiBold
                                  : AppTextStyles.weightRegular,
                            ),
                      ),
                      selectedColor: accentColor,
                      backgroundColor: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      side: BorderSide(
                        color: isSelected ? accentColor : Colors.transparent,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusXxl,
                        ),
                      ),
                      onSelected: (_) {
                        if (index != _selectedIndex) {
                          setState(() => _selectedIndex = index);
                          _loadChangelog(index);
                        }
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: AppDimens.spacingSm),
            Divider(
              color: MainScreenColors.getTextColor(
                isDarkMode,
              ).withValues(alpha: AppDimens.opacityLight),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: SizedBox(
                        width: AppDimens.progressSmall,
                        height: AppDimens.progressSmall,
                        child: CircularProgressIndicator(
                          strokeWidth: AppDimens.progressStroke,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accentColor,
                          ),
                        ),
                      ),
                    )
                  : Markdown(
                      controller: scrollController,
                      data: _changelog,
                      padding: const EdgeInsets.all(AppDimens.paddingXl),
                      styleSheet: MarkdownStyleSheet(
                        p: AppTextStyles.bodyMd(
                          isDarkMode: isDarkMode,
                        ).copyWith(height: AppTextStyles.lineHeightRelaxed),
                        h1: AppTextStyles.titleLg(isDarkMode: isDarkMode),
                        h2: AppTextStyles.heading(isDarkMode: isDarkMode),
                        h3: AppTextStyles.bodyLg(
                          isDarkMode: isDarkMode,
                        ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                        code: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                            .copyWith(
                              fontFamily: 'monospace',
                              backgroundColor: widget.accentColor.withValues(
                                alpha: 0.1,
                              ),
                            ),
                        codeblockDecoration: BoxDecoration(
                          color: widget.accentColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                        ),
                        listBullet: AppTextStyles.bodyMd(
                          isDarkMode: isDarkMode,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: widget.accentColor,
                              width: 3,
                            ),
                          ),
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: AppDimens.opacityLight),
                            ),
                          ),
                        ),
                      ),
                      onTapLink: (text, href, title) async {
                        if (href != null &&
                            await canLaunchUrl(Uri.parse(href))) {
                          await launchUrl(Uri.parse(href));
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
