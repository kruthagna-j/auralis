import 'package:flutter/material.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

enum AppSnackBarType { info, success, error, warning }

class AppSnackBar {
  AppSnackBar._();

  static Color _bgColor(AppSnackBarType type, {Color? accentColor}) {
    switch (type) {
      case AppSnackBarType.success:
        return accentColor ?? const Color(0xFF2E7D32); // deep green
      case AppSnackBarType.error:
        return const Color(0xFFC62828); // dark red
      case AppSnackBarType.warning:
        return const Color(0xFFE65100); // deep orange
      case AppSnackBarType.info:
        return accentColor ?? const Color(0xFF37474F); // blue-grey
    }
  }

  static IconData _icon(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_rounded;
      case AppSnackBarType.error:
        return Icons.error_rounded;
      case AppSnackBarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackBarType.info:
        return Icons.info_rounded;
    }
  }

  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.info,
    Color? accentColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final bg = _bgColor(type, accentColor: accentColor);
    final effectiveDuration =
        duration ??
        (type == AppSnackBarType.error || type == AppSnackBarType.warning
            ? const Duration(seconds: 4)
            : const Duration(seconds: 3));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(_icon(type), color: Colors.white, size: AppDimens.iconMd),
              SizedBox(width: AppDimens.spacingMd),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMd().copyWith(
                    color: Colors.white,
                    fontWeight: AppTextStyles.weightMedium,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          duration: effectiveDuration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDimens.paddingLg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          elevation: AppDimens.elevationMedium,
          action: action,
        ),
      );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Color? accentColor,
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppSnackBarType.success,
    accentColor: accentColor,
    duration: duration,
    action: action,
  );

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppSnackBarType.error,
    duration: duration,
    action: action,
  );

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppSnackBarType.warning,
    duration: duration,
    action: action,
  );

  static void showInfo(
    BuildContext context,
    String message, {
    Color? accentColor,
    Duration? duration,
    SnackBarAction? action,
  }) => show(
    context,
    message,
    type: AppSnackBarType.info,
    accentColor: accentColor,
    duration: duration,
    action: action,
  );
}
