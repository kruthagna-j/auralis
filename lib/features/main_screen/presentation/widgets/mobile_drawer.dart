import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../downloads/presentation/screens/downloads_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../stats/presentation/screens/stats_screen.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;
    final mq = MediaQuery.of(context);
    final double _drawerIconScale = mq.textScaleFactor > 1.0
        ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0)
        : 1.0;
    final double _drawerTextCap = mq.textScaleFactor > 1.0
        ? 1.0
        : mq.textScaleFactor;

    return Drawer(
      backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
      child: MediaQuery(
        data: mq.copyWith(textScaleFactor: _drawerTextCap),
        child: Column(
          children: [
            _buildDrawerHeader(
              context,
              isDarkMode,
              accentColor,
              _drawerIconScale,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMainMenuSection(
                      context,
                      isDarkMode,
                      _drawerIconScale,
                    ),
                    const Divider(),
                    _buildSocialLinksSection(
                      context,
                      isDarkMode,
                      accentColor,
                      _drawerIconScale,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomSection(context, isDarkMode, _drawerIconScale),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(
    BuildContext context,
    bool isDarkMode,
    Color accentColor,
    double iconScale,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingLg,
        MediaQuery.of(context).padding.top +
            (AppDimens.spacing5Xl + AppDimens.spacingSm),
        AppDimens.paddingLg,
        AppDimens.paddingXl,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.8), accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimens.radiusXl),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppDimens.radiusSm * iconScale,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: AppDimens.elevationMedium,
                  offset: const Offset(0, AppDimens.spacingS),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                AppDimens.radiusSm * iconScale,
              ),
              child: Image.asset(
                'assets/default_artwork.png',
                width: AppDimens.thumbnailLarge * iconScale,
                height: AppDimens.thumbnailLarge * iconScale,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: AppDimens.spacingMd * iconScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auralis',
                  style: AppTextStyles.titleLg(isDarkMode: isDarkMode).copyWith(
                    color: Colors.white,
                    fontWeight: AppTextStyles.weightBold,
                  ),
                ),
                SizedBox(height: AppDimens.spacingXs * iconScale),
                Text(
                  'welcome'.tr(),
                  style: AppTextStyles.body2(
                    isDarkMode: isDarkMode,
                  ).copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuSection(
    BuildContext context,
    bool isDarkMode,
    double iconScale,
  ) {
    return Column(
      children: [
        _buildMenuItem(
          context,
          icon: Icons.settings_rounded,
          title: 'settings'.tr(),
          onTap: () => _navigateTo(context, const SettingsScreen()),
          isDarkMode: isDarkMode,
          iconScale: iconScale,
        ),
        _buildMenuItem(
          context,
          icon: Icons.download_done_rounded,
          title: 'downloads'.tr(),
          onTap: () => _navigateTo(context, const DownloadsScreen()),
          isDarkMode: isDarkMode,
          iconScale: iconScale,
        ),
        _buildMenuItem(
          context,
          icon: Icons.show_chart_rounded,
          title: 'stats'.tr(),
          onTap: () => _navigateTo(context, StatsScreen()),
          isDarkMode: isDarkMode,
          iconScale: iconScale,
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection(
    BuildContext context,
    bool isDarkMode,
    Color accentColor,
    double iconScale,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimens.paddingLg,
              bottom: AppDimens.spacingSm,
            ),
            child: Text(
              'connect_with_us'.tr(),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialButton(
                context,
                icon: Icons.language,
                label: 'Website',
                url: 'https://github.com/kruthagna-j/auralis-app',
                color: accentColor,
                isDarkMode: isDarkMode,
                iconScale: iconScale,
              ),
              _buildSocialButton(
                context,
                icon: Icons.telegram,
                label: 'Telegram',
                url: 'https://github.com/kruthagna-j/auralis-app',
                color: accentColor,
                isDarkMode: isDarkMode,
                iconScale: iconScale,
              ),
              _buildSocialButton(
                context,
                icon: Icons.code,
                label: 'GitHub',
                url: 'https://github.com/kruthagna-j/auralis-app',
                color: accentColor,
                isDarkMode: isDarkMode,
                iconScale: iconScale,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    BuildContext context,
    bool isDarkMode,
    double iconScale,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimens.paddingLg * iconScale),
      child: Column(
        children: [
          const Divider(),
          ListTile(
            leading: Icon(Icons.share, size: AppDimens.iconLg * iconScale),
            title: Text(
              'share_app'.tr(),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
            ),
            onTap: () {
              Navigator.pop(context);
              _shareApp();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDarkMode,
    double iconScale = 1.0,
  }) {
    return ListTile(
      leading: Icon(icon, size: AppDimens.iconLg * iconScale),
      title: Text(
        title,
        style: AppTextStyles.subtitle(
          isDarkMode: isDarkMode,
        ).copyWith(fontSize: AppTextStyles.fontSizeSubtitle * iconScale),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
    required Color color,
    required bool isDarkMode,
    double iconScale = 1.0,
  }) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppDimens.paddingMd * iconScale),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimens.iconMd * iconScale),
          ),
          SizedBox(height: AppDimens.spacingXs * iconScale),
          Text(label, style: AppTextStyles.caption(isDarkMode: isDarkMode)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (context) => screen));
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out Auralis - Your personal music companion!\nhttps://github.com/kruthagna-j/auralis-app',
        subject: 'Auralis Music App',
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
