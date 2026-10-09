import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/models/ota_model.dart';
import '../../data/providers/ota_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class OTAScreen extends StatefulWidget {
  const OTAScreen({Key? key}) : super(key: key);

  @override
  State<OTAScreen> createState() => _OTAScreenState();
}

class _OTAScreenState extends State<OTAScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDimens.animSlow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? MainScreenColors.darkBackgroundColor
            : MainScreenColors.lightBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? Colors.transparent
              : MainScreenColors.getSurfaceColor(false),
          elevation: 0,
          title: Text(
            'ota_app_update_title'.tr(),
            style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: MainScreenColors.getTextColor(isDarkMode),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
        ),
        body: Consumer<OTAProvider>(
          builder: (context, otaProvider, child) {
            return RefreshIndicator(
              color: accentColor,
              onRefresh: () async => otaProvider.checkForUpdates(
                showChecking: false,
                showNoUpdateMessage: true,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBody(
                  context,
                  otaProvider,
                  isDarkMode,
                  accentColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    if (Platform.isLinux) {
      return _buildLinuxRedirect(context, otaProvider, isDarkMode, accentColor);
    }

    switch (otaProvider.status) {
      case OTAStatus.checking:
        return _buildCheckingUpdate(isDarkMode, accentColor);
      case OTAStatus.updateAvailable:
        return _buildUpdateAvailable(
          context,
          otaProvider,
          isDarkMode,
          accentColor,
        );
      case OTAStatus.downloading:
        return _buildDownloading(otaProvider, isDarkMode, accentColor);
      case OTAStatus.downloaded:
        return _buildReadyToInstall(
          context,
          otaProvider,
          isDarkMode,
          accentColor,
        );
      case OTAStatus.installing:
        return _buildInstalling(isDarkMode, accentColor);
      case OTAStatus.installed:
        return _buildInstalled(isDarkMode, accentColor);
      case OTAStatus.error:
        return _buildError(context, otaProvider, isDarkMode, accentColor);
      case OTAStatus.noUpdate:
        return _buildNoUpdate(isDarkMode, accentColor);
      default:
        return _buildInitial(context, otaProvider, isDarkMode, accentColor);
    }
  }

  Widget _buildCheckingUpdate(bool isDarkMode, Color accentColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: accentColor,
                strokeWidth: AppDimens.progressStroke,
              ),
              const SizedBox(height: AppDimens.spacingXxl),
              Text(
                'ota_checking_for_updates'.tr(),
                style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateAvailable(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    final updateInfo = otaProvider.updateInfo!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUpdateHeader(updateInfo, isDarkMode, accentColor),
          const SizedBox(height: 24),

          _buildUpdateDetails(updateInfo, isDarkMode, accentColor),
          const SizedBox(height: 24),

          _buildWhatsNewSection(updateInfo, isDarkMode, accentColor),
          const SizedBox(height: 24),

          if (updateInfo.bugFixes.isNotEmpty)
            _buildBugFixesSection(updateInfo, isDarkMode, accentColor),
          const SizedBox(height: 32),

          _buildActionButtons(context, otaProvider, isDarkMode, accentColor),
        ],
      ),
    );
  }

  Widget _buildUpdateHeader(
    OTAUpdateInfo updateInfo,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingXl),
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: AppDimens.dividerHeight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
                child: Icon(
                  Icons.system_update,
                  color: accentColor,
                  size: AppDimens.iconXl,
                ),
              ),
              const SizedBox(width: AppDimens.spacingLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ota_update_available_title'.tr(
                        args: [updateInfo.latestVersion],
                      ),
                      style: AppTextStyles.titleLg(isDarkMode: isDarkMode),
                    ),
                    Text(
                      'ota_update_size'.tr(args: [updateInfo.size]),
                      style: AppTextStyles.bodyMd(
                        isDarkMode: isDarkMode,
                        color: MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor, width: 1),
                ),
                child: Text(
                  'ota_update_available'.tr(),
                  style: GoogleFonts.poppins(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingLg),
          Text(
            updateInfo.releaseNotes,
            style: AppTextStyles.bodyMd(
              isDarkMode: isDarkMode,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDetails(
    OTAUpdateInfo updateInfo,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDetailItem(
              'Release Date',
              DateFormat('MMM dd, yyyy').format(updateInfo.releaseDate),
              Icons.calendar_today,
              isDarkMode,
              accentColor,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildDetailItem(
              'Version Code',
              updateInfo.versionCode.toString(),
              Icons.tag,
              isDarkMode,
              accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    String title,
    String value,
    IconData icon,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: MainScreenColors.getTextColor(isDarkMode),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsNewSection(
    OTAUpdateInfo updateInfo,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: accentColor, size: AppDimens.iconMd),
            const SizedBox(width: AppDimens.spacingSm),
            Text(
              "What's New",
              style: AppTextStyles.sectionHeader(accentColor: accentColor),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.spacingMd),
        ...updateInfo.updateLog.map(
          (item) => _buildChangeLogItem(item, isDarkMode),
        ),
        if (updateInfo.features.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'New Features:',
            style: GoogleFonts.poppins(
              color: MainScreenColors.getTextColor(isDarkMode),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...updateInfo.features.map(
            (feature) => _buildChangeLogItem('✨ $feature', isDarkMode),
          ),
        ],
      ],
    );
  }

  Widget _buildBugFixesSection(
    OTAUpdateInfo updateInfo,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bug_report, color: accentColor, size: AppDimens.iconMd),
            const SizedBox(width: AppDimens.spacingSm),
            Text(
              'Bug Fixes',
              style: AppTextStyles.sectionHeader(accentColor: accentColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...updateInfo.bugFixes.map(
          (fix) => _buildChangeLogItem('🐛 $fix', isDarkMode),
        ),
      ],
    );
  }

  Widget _buildChangeLogItem(String item, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppDimens.spacingS,
            height: AppDimens.spacingS,
            margin: const EdgeInsets.only(
              top: AppDimens.spacingSm,
              right: AppDimens.spacingMd,
            ),
            decoration: BoxDecoration(
              color: MainScreenColors.getTextColor(isDarkMode),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: AppTextStyles.bodyMd(
                isDarkMode: isDarkMode,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: AppDimens.buttonHeightLarge,
          child: ElevatedButton(
            onPressed: () => otaProvider.downloadUpdate(),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download, size: AppDimens.iconMd),
                const SizedBox(width: AppDimens.spacingSm),
                Text(
                  'Download Update',
                  style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                ),
              ],
            ),
          ),
        ),
        ...[
          const SizedBox(height: AppDimens.spacingSm),
          SizedBox(
            width: double.infinity,
            height: AppDimens.buttonHeightMedium,
            child: TextButton(
              onPressed: () {
                otaProvider.skipVersion();
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                ),
              ),
              child: Text(
                'Skip This Version',
                style: AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                ).copyWith(fontWeight: AppTextStyles.weightMedium),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDownloading(
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    final progress = otaProvider.downloadProgress;
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: AppDimens.animLong,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1 + (1 - value) * 0.1,
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: accentColor,
                      size: AppDimens.iconHuge,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimens.spacingXxxl),

              SizedBox(
                width: AppDimens.progressCircleLarge,
                height: AppDimens.progressCircleLarge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress != null ? progress.percentage / 100 : 0,
                      strokeWidth: AppDimens.progressStrokeLg,
                      color: accentColor,
                      backgroundColor: accentColor.withValues(alpha: 0.2),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          progress != null
                              ? '${progress.percentage.toInt()}%'
                              : '0%',
                          style: AppTextStyles.display(isDarkMode: isDarkMode),
                        ),
                        if (progress != null)
                          Text(
                            '${progress.formattedDownloaded} / ${progress.formattedTotal}',
                            style: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                                .copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: 0.7),
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spacingXxxl),

              Text(
                'ota_downloading_update'.tr(),
                style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
              ),

              const SizedBox(height: AppDimens.buttonHeightMedium),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => otaProvider.cancelDownload(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                      width: AppDimens.borderWidthThick,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: AppDimens.iconMd,
                  ),
                  label: Text(
                    'ota_cancel_download'.tr(),
                    style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadyToInstall(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingXxl),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: accentColor,
                size: AppDimens.iconStatus,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxxl),

            Text(
              'ota_download_complete'.tr(),
              style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
            ),
            const SizedBox(height: 16),

            Text(
              'ota_ready_to_install_message'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxxl),

            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: () => otaProvider.installUpdate(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.install_mobile, size: AppDimens.iconMd),
                    const SizedBox(width: AppDimens.spacingSm),
                    Text(
                      'ota_install_update'.tr(),
                      style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstalling(bool isDarkMode, Color accentColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: accentColor,
                strokeWidth: AppDimens.progressStroke,
              ),
              const SizedBox(height: AppDimens.spacingXxl),
              Text(
                'ota_installing_update'.tr(),
                style: AppTextStyles.titleSm(isDarkMode: isDarkMode),
              ),
              const SizedBox(height: AppDimens.spacingLg),
              Text(
                'ota_please_wait_install'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstalled(bool isDarkMode, Color accentColor) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingXxl),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: AppDimens.iconStatus,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxxl),
            Text(
              'ota_update_installed'.tr(),
              style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              'ota_update_installed_message'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingXxl),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: AppDimens.iconStatus,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxxl),

            Text(
              'ota_update_failed'.tr(),
              style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
            ),
            const SizedBox(height: AppDimens.spacingLg),

            Text(
              otaProvider.errorMessage ?? 'ota_update_failed_message'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimens.spacingXxxl),

            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: () {
                  otaProvider.reset();
                  otaProvider.checkForUpdates();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'ota_try_again'.tr(),
                  style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUpdate(bool isDarkMode, Color accentColor) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingXxl),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: accentColor,
                  size: AppDimens.iconStatus,
                ),
              ),
              const SizedBox(height: AppDimens.spacingXxxl),
              Text(
                'ota_up_to_date'.tr(),
                style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
              ),
              const SizedBox(height: AppDimens.spacingLg),
              Text(
                'ota_up_to_date_message'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinuxRedirect(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.open_in_new,
                  size: AppDimens.iconStatus,
                  color: accentColor,
                ),
                const SizedBox(height: AppDimens.spacingXxxl),
                Text(
                  'Updates are handled via GitHub releases.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
                ),
                const SizedBox(height: AppDimens.spacingLg),
                Text(
                  'Please visit the releases page to download the latest version of the app.',

                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                    color: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppDimens.spacingXxxl),
                SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonHeightLarge,
                  child: ElevatedButton(
                    onPressed: () => otaProvider.openReleasePage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Open Releases',
                      style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitial(
    BuildContext context,
    OTAProvider otaProvider,
    bool isDarkMode,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.system_update,
                color: accentColor,
                size: AppDimens.iconSplash,
              ),
              const SizedBox(height: AppDimens.spacingXxxl),
              Text(
                'ota_check_for_updates'.tr(),
                style: AppTextStyles.headingLg(isDarkMode: isDarkMode),
              ),
              const SizedBox(height: AppDimens.spacingLg),
              Text(
                'ota_check_for_updates_message'.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppDimens.spacingXxxl),

              SizedBox(
                width: AppDimens.buttonWidthMedium,
                height: AppDimens.buttonHeightLarge,
                child: ElevatedButton(
                  onPressed: () =>
                      otaProvider.checkForUpdates(showNoUpdateMessage: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'ota_check_now'.tr(),
                    style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
