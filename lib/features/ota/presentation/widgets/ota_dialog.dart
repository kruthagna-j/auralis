import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/models/ota_model.dart';
import '../../data/providers/ota_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../screens/ota_screen.dart';

class OTADialog extends StatelessWidget {
  final OTAUpdateInfo updateInfo;

  const OTADialog({Key? key, required this.updateInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;
    final otaProvider = Provider.of<OTAProvider>(context);

    return PopScope(
      canPop: true,
      child: AlertDialog(
        backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(
          AppDimens.paddingXxl,
          0,
          AppDimens.paddingXxl,
          AppDimens.paddingXxl,
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.paddingXl,
            horizontal: AppDimens.paddingXxl,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimens.radiusXxl),
              topRight: Radius.circular(AppDimens.radiusXxl),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.system_update_alt,
                color: accentColor,
                size: AppDimens.iconXxl,
              ),
              const SizedBox(width: AppDimens.spacingMd),
              Expanded(
                child: Text(
                  'new_update_available'.tr(),
                  style: AppTextStyles.titleLg(
                    isDarkMode: isDarkMode,
                  ).copyWith(color: accentColor),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.spacingXl),
            Text(
              'Version: ${updateInfo.latestVersion} (${updateInfo.versionCode})',
              style: AppTextStyles.subtitle(
                isDarkMode: isDarkMode,
              ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
            ),
            const SizedBox(height: AppDimens.spacingXs),
            Text(
              'Size: ${updateInfo.size}',
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                color: MainScreenColors.getTextColor(
                  isDarkMode,
                ).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppDimens.spacingLg),
            Text(
              updateInfo.releaseNotes,
              style: AppTextStyles.bodyMd(
                isDarkMode: isDarkMode,
              ).copyWith(height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimens.spacingXxl),
            const SizedBox(height: AppDimens.spacingXxl),
            SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: () {
                  if (Platform.isLinux) {
                    otaProvider.openReleasePage();
                    otaProvider.setUpdateUIShown(false);
                    Navigator.pop(context);
                  } else {
                    otaProvider.setOTAScreenActive(true);
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OTAScreen(),
                        ),
                      ).then((_) {
                        otaProvider.setOTAScreenActive(false);
                        otaProvider.setUpdateUIShown(false);
                      });
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                ),
                child: Text(
                  Platform.isLinux ? 'Open Releases' : 'update_now'.tr(),
                  style: AppTextStyles.subtitle(
                    isDarkMode: isDarkMode,
                  ).copyWith(fontWeight: AppTextStyles.weightBold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.spacingSm),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    otaProvider.skipVersion();
                    Navigator.pop(context);
                    otaProvider.setUpdateUIShown(false);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: 0.7),
                  ),
                  child: Text(
                    'skip_this_version',
                    style: AppTextStyles.bodyMd(
                      isDarkMode: isDarkMode,
                    ).copyWith(fontWeight: AppTextStyles.weightMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
