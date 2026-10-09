import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

class SearchSuggestionsList extends StatelessWidget {
  final bool isDarkMode;
  final Color accentColor;
  final String searchText;
  final ValueNotifier<List<String>> searchHistoryNotifier;
  final ValueNotifier<List<String>> searchSuggestionsNotifier;
  final ValueNotifier<List<dynamic>> quickSongsNotifier;
  final VoidCallback onInitializeSearchHistory;
  final ValueChanged<String> onSuggestionTapped;
  final ValueChanged<String> onHistoryItemTapped;
  final ValueChanged<String> onHistoryItemRemoved;
  final ValueChanged<dynamic> onQuickSongTapped;

  const SearchSuggestionsList({
    Key? key,
    required this.isDarkMode,
    required this.accentColor,
    required this.searchText,
    required this.searchHistoryNotifier,
    required this.searchSuggestionsNotifier,
    required this.quickSongsNotifier,
    required this.onInitializeSearchHistory,
    required this.onSuggestionTapped,
    required this.onHistoryItemTapped,
    required this.onHistoryItemRemoved,
    required this.onQuickSongTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppDimens.isDesktop(context);
    final maxWidth = isDesktop ? AppDimens.maxContentWidth : double.infinity;

    if (searchText.trim().isEmpty) {
      return _buildSearchHistory(maxWidth);
    }

    return _buildSuggestionsAndQuickResults(maxWidth);
  }

  Widget _buildSearchHistory(double maxWidth) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: searchHistoryNotifier,
      builder: (context, searchHistory, child) {
        if (searchHistory.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => onInitializeSearchHistory(),
          );
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(
                'search_hint'.tr(),
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView.builder(
              itemCount: searchHistory.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: 0.5),
                  ),
                  title: Text(
                    searchHistory[index],
                    style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.5),
                    ),
                    onPressed: () => onHistoryItemRemoved(searchHistory[index]),
                  ),
                  onTap: () => onHistoryItemTapped(searchHistory[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsAndQuickResults(double maxWidth) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: searchSuggestionsNotifier,
      builder: (context, searchSuggestions, child) {
        return ValueListenableBuilder<List<dynamic>>(
          valueListenable: quickSongsNotifier,
          builder: (context, quickSongs, child) {
            if (searchSuggestions.isEmpty && quickSongs.isEmpty) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Text(
                    'search_hint'.tr(),
                    style: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                        .copyWith(
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: 0.5),
                        ),
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  children: [
                    ...searchSuggestions.map(
                      (suggestion) => ListTile(
                        leading: Icon(
                          Icons.search,
                          color: MainScreenColors.getTextColor(
                            isDarkMode,
                          ).withValues(alpha: 0.5),
                        ),
                        title: Text(
                          suggestion,
                          style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                        ),
                        onTap: () => onSuggestionTapped(suggestion),
                      ),
                    ),
                    if (quickSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingLg,
                        ),
                        child: Text(
                          'Quick Results',
                          style: AppTextStyles.subtitle(isDarkMode: isDarkMode)
                              .copyWith(
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ).withValues(alpha: 0.7),
                                fontWeight: AppTextStyles.weightSemiBold,
                              ),
                        ),
                      ),
                      ...quickSongs.map(
                        (song) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.paddingLg,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusSm,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: song.thumbnails.first.url,
                              width: AppDimens.shimmerListTile,
                              height: AppDimens.shimmerListTile,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: MainScreenColors.getSurfaceColor(
                                  isDarkMode,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: MainScreenColors.getSurfaceColor(
                                  isDarkMode,
                                ),
                                child: Icon(
                                  Icons.error,
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.name,
                            style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist.name,
                            style: AppTextStyles.body2(isDarkMode: isDarkMode)
                                .copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: 0.5),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onQuickSongTapped(song),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
