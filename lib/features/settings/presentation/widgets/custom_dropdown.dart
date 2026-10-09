import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final bool isDarkMode;
  final Color accentColor;
  final String? subtitle;

  const CustomDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDarkMode,
    required this.accentColor,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = MainScreenColors.getTextColor(isDarkMode);
    final surfaceColor = isDarkMode
        ? MainScreenColors.darkSurfaceColor
        : MainScreenColors.lightSurfaceColor;

    return GestureDetector(
      onTap: () => _showDropdownDialog(context, textColor, surfaceColor),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingSm,
          vertical: AppDimens.paddingXs,
        ),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: AppDimens.borderWidthThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: AppTextStyles.bodyMd(
                isDarkMode: isDarkMode,
                color: textColor,
              ).copyWith(fontWeight: AppTextStyles.weightMedium),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: textColor.withValues(alpha: 0.7),
              size: AppDimens.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  void _showDropdownDialog(
    BuildContext context,
    Color textColor,
    Color surfaceColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          title: Text(
            subtitle ?? 'select_option'.tr(),
            style: AppTextStyles.titleSm(
              isDarkMode: isDarkMode,
              color: textColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == value;
                  return InkWell(
                    onTap: () {
                      onChanged(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimens.spacingMd,
                        horizontal: AppDimens.paddingLg,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.toString(),
                              style:
                                  AppTextStyles.bodyMd(
                                    isDarkMode: isDarkMode,
                                    color: isSelected ? accentColor : textColor,
                                  ).copyWith(
                                    fontWeight: isSelected
                                        ? AppTextStyles.weightSemiBold
                                        : AppTextStyles.weightRegular,
                                  ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: accentColor,
                              size: AppDimens.iconMd,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'cancel'.tr(),
                style: AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                  color: accentColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
