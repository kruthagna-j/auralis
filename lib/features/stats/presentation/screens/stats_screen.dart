import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main_screen/presentation/screens/full_player_screen.dart';
import '../../../player/presentation/screens/player_ui.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/providers/stats_provider.dart';
import '../widgets/artist_list.dart';
import '../widgets/playback_bar_chart.dart';
import '../widgets/summary_card.dart';

class _StatsColors {
  static const Color dailyBar = Color(0xFF26C6DA);
  static const Color dailyBarDark = Color(0xFF00ACC1);
  static const Color dailyGradientTop = Color(0xFF26C6DA);
  static const Color dailyGradientBottom = Color(0xFF00838F);
  static const Color weeklyBar = Color(0xFFFFB74D);
  static const Color weeklyBarDark = Color(0xFFFFA726);
  static const Color weeklyGradientTop = Color(0xFFFFB74D);
  static const Color weeklyGradientBottom = Color(0xFFE65100);
  static const Color monthlyBar = Color(0xFFAB47BC);
  static const Color monthlyBarDark = Color(0xFF9C27B0);
  static const Color monthlyGradientTop = Color(0xFFCE93D8);
  static const Color monthlyGradientBottom = Color(0xFF6A1B9A);
}

class StatsScreen extends StatefulWidget {
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${twoDigits(minutes)}m ${twoDigits(seconds)}s';
    } else if (minutes > 0) {
      return '${minutes}m ${twoDigits(seconds)}s';
    } else {
      return '${seconds}s';
    }
  }

  String _shortDay(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } catch (_) {
      return dateKey;
    }
  }

  String _shortWeekLabel(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final dt = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return dateKey;
    }
  }

  String _shortMonth(String dateKey) {
    try {
      final parts = dateKey.split('-');
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return months[int.parse(parts[1]) - 1];
    } catch (_) {
      return dateKey;
    }
  }

  void _showFullPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => const FullPlayerScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isDesktopLayout = !AppDimens.isMobile(context);

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'playback_statistics'.tr(),
            style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: isDesktopLayout
              ? null
              : TabBar(
                  controller: _tabController,
                  indicatorColor: settingsProvider.accentColor,
                  labelColor: MainScreenColors.getTextColor(isDarkMode),
                  unselectedLabelColor: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.5),
                  labelStyle: AppTextStyles.bodyMd(
                    isDarkMode: isDarkMode,
                  ).copyWith(fontWeight: AppTextStyles.weightSemiBold),
                  tabs: [
                    Tab(text: 'daily'.tr()),
                    Tab(text: 'weekly'.tr()),
                    Tab(text: 'monthly'.tr()),
                  ],
                ),
        ),
        body: Consumer<PlayerProvider>(
          builder: (context, playerProvider, _) {
            final hasPlayer =
                playerProvider.currentSong != null ||
                playerProvider.lastPlayedSong != null ||
                playerProvider.currentLocalSong != null;

            final mq = MediaQuery.of(context);
            final double navIconScale = mq.textScaleFactor > 1.0
                ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
                : 1.0;

            return Stack(
              children: [
                isDesktopLayout
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(AppDimens.paddingLg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _DailyTab(
                                statsProvider: statsProvider,
                                isDarkMode: isDarkMode,
                                accentColor: settingsProvider.accentColor,
                                formatDuration: _formatDuration,
                                shortDay: _shortDay,
                                isInline: true,
                              ),
                            ),
                            SizedBox(width: AppDimens.spacingLg),
                            Expanded(
                              child: _WeeklyTab(
                                statsProvider: statsProvider,
                                isDarkMode: isDarkMode,
                                accentColor: settingsProvider.accentColor,
                                formatDuration: _formatDuration,
                                shortWeekLabel: _shortWeekLabel,
                                isInline: true,
                              ),
                            ),
                            SizedBox(width: AppDimens.spacingLg),
                            Expanded(
                              child: _MonthlyTab(
                                statsProvider: statsProvider,
                                isDarkMode: isDarkMode,
                                accentColor: settingsProvider.accentColor,
                                formatDuration: _formatDuration,
                                shortMonth: _shortMonth,
                                isInline: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.only(
                          bottom: hasPlayer
                              ? AppDimens.miniPlayerHeight * navIconScale
                              : 0,
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _DailyTab(
                              statsProvider: statsProvider,
                              isDarkMode: isDarkMode,
                              accentColor: settingsProvider.accentColor,
                              formatDuration: _formatDuration,
                              shortDay: _shortDay,
                            ),
                            _WeeklyTab(
                              statsProvider: statsProvider,
                              isDarkMode: isDarkMode,
                              accentColor: settingsProvider.accentColor,
                              formatDuration: _formatDuration,
                              shortWeekLabel: _shortWeekLabel,
                            ),
                            _MonthlyTab(
                              statsProvider: statsProvider,
                              isDarkMode: isDarkMode,
                              accentColor: settingsProvider.accentColor,
                              formatDuration: _formatDuration,
                              shortMonth: _shortMonth,
                            ),
                          ],
                        ),
                      ),

                if (!isDesktopLayout && hasPlayer)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).appBarTheme.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      child: SizedBox(
                        height: AppDimens.miniPlayerHeight * navIconScale,
                        child: PlayerUI(
                          showFullScreen: false,
                          isEmbedded: true,
                          onMinimize: () {},
                          onExpand: () => _showFullPlayerBottomSheet(context),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DailyTab extends StatefulWidget {
  final StatsProvider statsProvider;
  final bool isDarkMode;
  final Color accentColor;
  final String Function(Duration) formatDuration;
  final String Function(String) shortDay;
  final bool isInline;

  const _DailyTab({
    required this.statsProvider,
    required this.isDarkMode,
    required this.accentColor,
    required this.formatDuration,
    required this.shortDay,
    this.isInline = false,
  });

  @override
  State<_DailyTab> createState() => _DailyTabState();
}

class _DailyTabState extends State<_DailyTab> {
  bool _showSongs = false;

  @override
  Widget build(BuildContext context) {
    final daily = widget.statsProvider.getDailyStats(days: 7);
    final todayTime = widget.statsProvider.todayPlaybackTime;
    final todaySongs = widget.statsProvider.todaySongsPlayed;
    final periodArtists = widget.statsProvider.dailyArtists;
    final periodArtistSongCounts = widget.statsProvider.dailyArtistSongCounts;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryCard(
          title: 'today\'s_listening'.tr(),
          value: widget.formatDuration(todayTime),
          icon: Icons.today,
          color: _StatsColors.dailyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingSm),
        SummaryCard(
          title: 'songs_played_today'.tr(),
          value: '$todaySongs',
          icon: Icons.library_music,
          color: _StatsColors.dailyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingXl),
        Row(
          children: [
            Expanded(
              child: Text(
                'last_7_days'.tr(),
                style: AppTextStyles.subtitle(isDarkMode: widget.isDarkMode)
                    .copyWith(
                      color: MainScreenColors.getTextColor(widget.isDarkMode),
                    ),
              ),
            ),
            _ChartToggle(
              showSongs: _showSongs,
              color: _StatsColors.dailyBar,
              isDarkMode: widget.isDarkMode,
              onChanged: (v) => setState(() => _showSongs = v),
            ),
          ],
        ),
        SizedBox(height: AppDimens.spacingMd),
        SizedBox(
          height: AppDimens.chartHeight,
          child: PlaybackBarChart(
            entries: daily,
            barColor: _StatsColors.dailyBar,
            gradientTop: _StatsColors.dailyGradientTop,
            gradientBottom: _StatsColors.dailyGradientBottom,
            labelBuilder: widget.shortDay,
            isDarkMode: widget.isDarkMode,
            showSongs: _showSongs,
          ),
        ),
        SizedBox(height: AppDimens.spacingXxl),
        Text(
          'top_artists'.tr(),
          style: AppTextStyles.subtitle(
            isDarkMode: widget.isDarkMode,
          ).copyWith(color: MainScreenColors.getTextColor(widget.isDarkMode)),
        ),
        SizedBox(height: AppDimens.spacingSm),
        ArtistList(
          artists: periodArtists,
          artistSongCounts: periodArtistSongCounts,
          color: _StatsColors.dailyBar,
          isDarkMode: widget.isDarkMode,
          formatDuration: widget.formatDuration,
        ),
      ],
    );

    if (widget.isInline) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimens.paddingLg),
      child: content,
    );
  }
}

class _WeeklyTab extends StatefulWidget {
  final StatsProvider statsProvider;
  final bool isDarkMode;
  final Color accentColor;
  final String Function(Duration) formatDuration;
  final String Function(String) shortWeekLabel;
  final bool isInline;

  const _WeeklyTab({
    required this.statsProvider,
    required this.isDarkMode,
    required this.accentColor,
    required this.formatDuration,
    required this.shortWeekLabel,
    this.isInline = false,
  });

  @override
  State<_WeeklyTab> createState() => _WeeklyTabState();
}

class _WeeklyTabState extends State<_WeeklyTab> {
  bool _showSongs = false;

  @override
  Widget build(BuildContext context) {
    final weekly = widget.statsProvider.getWeeklyStats(weeks: 4);
    final thisWeek = widget.statsProvider.thisWeekPlaybackTime;
    final thisWeekSongs = widget.statsProvider.thisWeekSongsPlayed;
    final periodArtists = widget.statsProvider.weeklyArtists;
    final periodArtistSongCounts = widget.statsProvider.weeklyArtistSongCounts;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryCard(
          title: 'this_week_listening'.tr(),
          value: widget.formatDuration(thisWeek),
          icon: Icons.date_range,
          color: _StatsColors.weeklyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingSm),
        SummaryCard(
          title: 'songs_played_this_week'.tr(),
          value: '$thisWeekSongs',
          icon: Icons.library_music,
          color: _StatsColors.weeklyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingXl),
        Row(
          children: [
            Expanded(
              child: Text(
                'last_4_weeks'.tr(),
                style: AppTextStyles.subtitle(isDarkMode: widget.isDarkMode)
                    .copyWith(
                      color: MainScreenColors.getTextColor(widget.isDarkMode),
                    ),
              ),
            ),
            _ChartToggle(
              showSongs: _showSongs,
              color: _StatsColors.weeklyBar,
              isDarkMode: widget.isDarkMode,
              onChanged: (v) => setState(() => _showSongs = v),
            ),
          ],
        ),
        SizedBox(height: AppDimens.spacingMd),
        SizedBox(
          height: AppDimens.chartHeight,
          child: PlaybackBarChart(
            entries: weekly,
            barColor: _StatsColors.weeklyBar,
            gradientTop: _StatsColors.weeklyGradientTop,
            gradientBottom: _StatsColors.weeklyGradientBottom,
            labelBuilder: (key) => 'W ${widget.shortWeekLabel(key)}',
            isDarkMode: widget.isDarkMode,
            showSongs: _showSongs,
          ),
        ),
        SizedBox(height: AppDimens.spacingXxl),
        Text(
          'top_artists'.tr(),
          style: AppTextStyles.subtitle(
            isDarkMode: widget.isDarkMode,
          ).copyWith(color: MainScreenColors.getTextColor(widget.isDarkMode)),
        ),
        SizedBox(height: AppDimens.spacingSm),
        ArtistList(
          artists: periodArtists,
          artistSongCounts: periodArtistSongCounts,
          color: _StatsColors.weeklyBar,
          isDarkMode: widget.isDarkMode,
          formatDuration: widget.formatDuration,
        ),
      ],
    );

    if (widget.isInline) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimens.paddingLg),
      child: content,
    );
  }
}

class _MonthlyTab extends StatefulWidget {
  final StatsProvider statsProvider;
  final bool isDarkMode;
  final Color accentColor;
  final String Function(Duration) formatDuration;
  final String Function(String) shortMonth;
  final bool isInline;

  const _MonthlyTab({
    required this.statsProvider,
    required this.isDarkMode,
    required this.accentColor,
    required this.formatDuration,
    required this.shortMonth,
    this.isInline = false,
  });

  @override
  State<_MonthlyTab> createState() => _MonthlyTabState();
}

class _MonthlyTabState extends State<_MonthlyTab> {
  bool _showSongs = false;

  @override
  Widget build(BuildContext context) {
    final monthly = widget.statsProvider.getMonthlyStats(months: 6);
    final thisMonth = widget.statsProvider.thisMonthPlaybackTime;
    final thisMonthSongs = widget.statsProvider.thisMonthSongsPlayed;
    final periodArtists = widget.statsProvider.monthlyArtists;
    final periodArtistSongCounts = widget.statsProvider.monthlyArtistSongCounts;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SummaryCard(
          title: 'this_month_listening'.tr(),
          value: widget.formatDuration(thisMonth),
          icon: Icons.calendar_month,
          color: _StatsColors.monthlyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingSm),
        SummaryCard(
          title: 'songs_played_this_month'.tr(),
          value: '$thisMonthSongs',
          icon: Icons.library_music,
          color: _StatsColors.monthlyBar,
          isDarkMode: widget.isDarkMode,
        ),
        SizedBox(height: AppDimens.spacingXl),
        Row(
          children: [
            Expanded(
              child: Text(
                'last_6_months'.tr(),
                style: AppTextStyles.subtitle(isDarkMode: widget.isDarkMode)
                    .copyWith(
                      color: MainScreenColors.getTextColor(widget.isDarkMode),
                    ),
              ),
            ),
            _ChartToggle(
              showSongs: _showSongs,
              color: _StatsColors.monthlyBar,
              isDarkMode: widget.isDarkMode,
              onChanged: (v) => setState(() => _showSongs = v),
            ),
          ],
        ),
        SizedBox(height: AppDimens.spacingMd),
        SizedBox(
          height: AppDimens.chartHeight,
          child: PlaybackBarChart(
            entries: monthly,
            barColor: _StatsColors.monthlyBar,
            gradientTop: _StatsColors.monthlyGradientTop,
            gradientBottom: _StatsColors.monthlyGradientBottom,
            labelBuilder: widget.shortMonth,
            isDarkMode: widget.isDarkMode,
            showSongs: _showSongs,
          ),
        ),
        SizedBox(height: AppDimens.spacingXxl),
        Text(
          'top_artists'.tr(),
          style: AppTextStyles.subtitle(
            isDarkMode: widget.isDarkMode,
          ).copyWith(color: MainScreenColors.getTextColor(widget.isDarkMode)),
        ),
        SizedBox(height: AppDimens.spacingSm),
        ArtistList(
          artists: periodArtists,
          artistSongCounts: periodArtistSongCounts,
          color: _StatsColors.monthlyBar,
          isDarkMode: widget.isDarkMode,
          formatDuration: widget.formatDuration,
        ),
      ],
    );

    if (widget.isInline) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimens.paddingLg),
      child: content,
    );
  }
}

class _ChartToggle extends StatelessWidget {
  final bool showSongs;
  final Color color;
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const _ChartToggle({
    required this.showSongs,
    required this.color,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _toggleChip(
          label: 'time'.tr(),
          selected: !showSongs,
          onTap: () => onChanged(false),
        ),
        SizedBox(width: AppDimens.spacingXs),
        _toggleChip(
          label: 'songs'.tr(),
          selected: showSongs,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animFast,
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.paddingMd,
          vertical: AppDimens.paddingXs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          border: Border.all(
            color: selected
                ? color
                : MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption(isDarkMode: isDarkMode).copyWith(
            fontWeight: selected
                ? AppTextStyles.weightSemiBold
                : FontWeight.normal,
            color: selected
                ? color
                : MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
