import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/connectivity_provider.dart';

class ConnectivityStatusWidget extends StatelessWidget {
  final Widget child;
  final bool showPersistentIndicator;

  const ConnectivityStatusWidget({
    Key? key,
    required this.child,
    this.showPersistentIndicator = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        return Stack(
          children: [
            child,
            if (!connectivity.isConnected && showPersistentIndicator)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildOfflineIndicator(context),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppDimens.paddingSm,
        horizontal: AppDimens.paddingLg,
      ),
      color: Colors.orange.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: AppDimens.iconXs),
          SizedBox(width: AppDimens.spacingSm),
          Text(
            'No internet connection - Offline mode',
            style: AppTextStyles.caption().copyWith(
              color: Colors.white,
              fontWeight: AppTextStyles.weightMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectivitySnackBar {
  static void show(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: AppDimens.iconMd,
            ),
            SizedBox(width: AppDimens.spacingMd),
            Text(
              isConnected
                  ? 'Internet connection restored'
                  : 'No internet connection - Using offline mode',
              style: AppTextStyles.bodyMd().copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange.shade700,
        duration: Duration(seconds: isConnected ? 2 : 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(AppDimens.paddingLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
      ),
    );
  }
}

class ConnectivityRetryWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? message;

  const ConnectivityRetryWidget({Key? key, this.onRetry, this.message})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, _) {
        if (connectivity.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(AppDimens.paddingLg),
          margin: EdgeInsets.all(AppDimens.paddingLg),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(
              color: Colors.orange.shade300,
              width: AppDimens.borderWidthThin,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off,
                size: AppDimens.iconHero,
                color: Colors.orange.shade600,
              ),
              SizedBox(height: AppDimens.spacingMd),
              Text(
                message ?? 'No internet connection',
                style: AppTextStyles.subtitle().copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.spacingSm),
              Text(
                'Please check your internet connection and try again.',
                style: AppTextStyles.bodyMd().copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                SizedBox(height: AppDimens.spacingLg),
                ElevatedButton.icon(
                  onPressed: () async {
                    await connectivity.refreshConnectivity();
                    if (connectivity.isConnected && onRetry != null) {
                      onRetry!();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
