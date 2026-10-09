import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/content_router.dart';
import 'home_screen_shimmer.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../data/providers/home_screen_provider.dart';
import '../../../../core/providers/settings_provider.dart';

class HomeSections extends StatelessWidget {
  const HomeSections({Key? key}) : super(key: key);

  void _openContentDetail(BuildContext context, dynamic content) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContentRouter(content: content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.select((SettingsProvider p) => p.accentColor);
    final provider = context.watch<HomeScreenProvider>();

    if (provider.isHomeSectionsLoading) {
      return ShimmerLoading.buildShimmerList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: provider.homeSections.map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.paddingLg),
              child: Text(
                section.title,
                style: AppTextStyles.titleLg().copyWith(color: accentColor),
              ),
            ),
            SizedBox(
              height: AppDimens.headerImageSm + AppDimens.spacingSm + 25,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: section.contents.length,
                itemBuilder: (context, index) {
                  final content = section.contents[index];
                  return ContentCard(
                    content: content,
                    isArtist: content.type == 'artist',
                    onTap: () => _openContentDetail(context, content),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class ContentCard extends StatelessWidget {
  final dynamic content;
  final bool isArtist;
  final VoidCallback onTap;

  const ContentCard({
    Key? key,
    required this.content,
    this.isArtist = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                isArtist ? AppDimens.radiusFull : AppDimens.radiusSm,
              ),
              child: CachedNetworkImage(
                imageUrl: content.thumbnails.first.url,
                height: AppDimens.headerImageSm,
                width: AppDimens.headerImageSm,
                fit: BoxFit.cover,
                placeholder: (context, url) => ShimmerLoading.buildShimmerRect(
                  width: AppDimens.headerImageSm,
                  height: AppDimens.headerImageSm,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[850],
                  child: const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.spacingSm),
            Text(
              content.name,
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
