import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDarkMode;
  final Color accentColor;

  const SettingsItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity(vertical: -2, horizontal: -2),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSm,
          vertical: AppDimens.paddingXs,
        ),
        minLeadingWidth: AppDimens.iconLg,
        horizontalTitleGap: AppDimens.spacingSm,
        leading: Container(
          padding: EdgeInsets.all(AppDimens.paddingXs),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          ),
          child: Icon(icon, color: accentColor, size: AppDimens.iconMd),
        ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMd(
            isDarkMode: isDarkMode,
          ).copyWith(fontWeight: AppTextStyles.weightMedium),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: AppTextStyles.settingsSubtitle(isDarkMode: isDarkMode),
                overflow: TextOverflow.ellipsis,
              ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDarkMode;
  final Color accentColor;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const SettingsToggleItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDarkMode,
    required this.accentColor,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsItem(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: SettingsToggle(
        value: value,
        onChanged: enabled ? onChanged : null,
        accentColor: accentColor,
        isDarkMode: isDarkMode,
        enabled: enabled,
      ),
      onTap:
          onTap ??
          (enabled && onChanged != null ? () => onChanged!(!value) : null),
      isDarkMode: isDarkMode,
      accentColor: accentColor,
    );
  }
}

class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    required this.isDarkMode,
    this.enabled = true,
  }) : super(key: key);

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDarkMode;
  final Color accentColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color enabledTrackColor = isDarkMode
        ? accentColor.withValues(alpha: value ? 0.32 : 0.16)
        : (value ? accentColor : accentColor.withValues(alpha: 0.16));
    final Color disabledTrackColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final Color trackColor = enabled ? enabledTrackColor : disabledTrackColor;
    final Color knobColor = enabled
        ? (isDarkMode ? accentColor : Colors.white)
        : Colors.grey.shade500;

    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 50,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: enabled ? trackColor : disabledTrackColor),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: knobColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDarkMode;
  final Color accentColor;

  const SettingsSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
    required this.isDarkMode,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingXs,
        AppDimens.spacingXxl,
        AppDimens.paddingXs,
        AppDimens.spacingMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: AppDimens.iconMdLg),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.titleSm(
              isDarkMode: isDarkMode,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
