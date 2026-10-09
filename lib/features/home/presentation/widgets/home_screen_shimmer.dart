import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_dimens.dart';

class ShimmerLoading {
  static Widget buildSectionHeader({double width = 180}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        height: AppDimens.iconLg,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        ),
      ),
    );
  }

  static Widget buildHorizontalListShimmer({
    int itemCount = 5,
    double cardSize = AppDimens.headerImageSm,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: cardSize,
                  width: cardSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                ),
                const SizedBox(height: AppDimens.spacingSm),
                Container(
                  height: AppDimens.iconSm,
                  width: cardSize * 0.9,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget buildStatsShimmer(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final cardHeight = isDesktop
        ? AppDimens.headerImageMd
        : AppDimens.headerImageSm;

    Widget _shimmerCard() {
      return Expanded(
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.only(right: AppDimens.spacingLg),
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: AppDimens.iconXl,
                width: AppDimens.iconXl,
                color: Colors.white,
              ),
              const SizedBox(height: AppDimens.spacingSm),
              Container(
                height: AppDimens.iconSm,
                width: 60,
                color: Colors.white,
              ),
              const SizedBox(height: AppDimens.spacingXs),
              Container(
                height: AppDimens.iconXs,
                width: 40,
                color: Colors.white,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerCard(),
                _shimmerCard(),
                Expanded(
                  child: Container(
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    ),
                    padding: const EdgeInsets.all(AppDimens.paddingLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: AppDimens.iconSm,
                          width: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppDimens.spacingSm),
                        Container(
                          height: AppDimens.iconSm,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: AppDimens.spacingXs),
                        Container(
                          height: AppDimens.iconXs,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(children: [_shimmerCard(), _shimmerCard()]),
                const SizedBox(height: AppDimens.spacingMd),
                Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  ),
                  padding: const EdgeInsets.all(AppDimens.paddingLg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: AppDimens.iconSm,
                        width: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: AppDimens.spacingSm),
                      Container(
                        height: AppDimens.iconSm,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: AppDimens.spacingXs),
                      Container(
                        height: AppDimens.iconXs,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static Widget buildShimmerRect({
    required double width,
    required double height,
    double borderRadius = AppDimens.radiusSm,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  static Widget buildShimmerCard({
    double width = AppDimens.headerImageSm,
    double height = AppDimens.shimmerSection,
  }) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Container(
              height: AppDimens.iconSm,
              width: width * 0.8,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: AppDimens.thumbnailDefault,
              height: AppDimens.thumbnailDefault,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusXs),
              ),
            ),
            title: Container(
              height: AppDimens.iconSm,
              width: double.infinity,
              color: Colors.white,
            ),
            subtitle: Container(
              height: AppDimens.iconXs,
              width: double.infinity,
              margin: const EdgeInsets.only(top: AppDimens.spacingXs),
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
