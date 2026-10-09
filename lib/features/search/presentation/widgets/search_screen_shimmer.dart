import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

class SearchShimmer {
  static Widget buildSearchListShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.only(top: AppDimens.spacingSm),
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingLg,
              vertical: AppDimens.spacingSm,
            ),
            leading: Container(
              width: AppDimens.shimmerListTile,
              height: AppDimens.shimmerListTile,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
            ),
            title: Container(
              height: AppTextStyles.fontSizeBody,
              width: double.infinity,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            ),
            subtitle: Container(
              height: AppTextStyles.fontSizeBody2,
              width: AppDimens.shimmerCardImage,
              margin: const EdgeInsets.only(top: AppDimens.spacingSm),
              color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
            ),
          );
        },
      ),
    );
  }

  static Widget buildHomeShimmer(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.paddingLg),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: AppTextStyles.fontSizeHeadingLg,
                width: AppDimens.shimmerSection,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                margin: const EdgeInsets.symmetric(
                  vertical: AppDimens.spacingSm,
                ),
              ),
              SizedBox(
                height: AppDimens.shimmerHorizontalSection,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, idx) {
                    return Container(
                      width: AppDimens.shimmerGridItem,
                      margin: const EdgeInsets.only(right: AppDimens.spacingLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: AppDimens.shimmerGridItem,
                            width: AppDimens.shimmerGridItem,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusSm,
                              ),
                            ),
                          ),
                          SizedBox(height: AppDimens.spacingSm),
                          Container(
                            height: AppTextStyles.fontSizeBody,
                            width: AppDimens.shimmerCardImage,
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                          ),
                          SizedBox(height: AppDimens.spacingXs),
                          Container(
                            height: AppTextStyles.fontSizeBody2,
                            width: AppDimens.shimmerCardImage,
                            color: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
