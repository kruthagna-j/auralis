import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MainScreenColors.getSurfaceColor(isDarkMode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMdLg),
      ),
      elevation: AppDimens.elevationLow,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppDimens.paddingSm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Icon(icon, color: color, size: AppDimens.iconXl),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
            color: MainScreenColors.getTextColor(
              isDarkMode,
            ).withValues(alpha: 0.7),
          ),
        ),
        subtitle: Text(
          value,
          style: AppTextStyles.heading(isDarkMode: isDarkMode).copyWith(
            fontWeight: AppTextStyles.weightBold,
            color: MainScreenColors.getTextColor(isDarkMode),
          ),
        ),
      ),
    );
  }
}
