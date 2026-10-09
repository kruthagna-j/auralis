import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/stats_provider.dart';

class PlaybackBarChart extends StatelessWidget {
  final List<DailyPlaybackEntry> entries;
  final Color barColor;
  final Color gradientTop;
  final Color gradientBottom;
  final String Function(String dateKey) labelBuilder;
  final bool isDarkMode;
  final bool showSongs;

  const PlaybackBarChart({
    required this.entries,
    required this.barColor,
    required this.gradientTop,
    required this.gradientBottom,
    required this.labelBuilder,
    required this.isDarkMode,
    this.showSongs = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showSongs) {
      return _buildSongsChart();
    }
    return _buildTimeChart();
  }

  Widget _buildTimeChart() {
    final maxMinutes = entries.fold<double>(
      0,
      (prev, e) => e.totalSeconds / 60 > prev ? e.totalSeconds / 60 : prev,
    );
    final topY = maxMinutes == 0 ? 10.0 : (maxMinutes * 1.3).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: topY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                MainScreenColors.getSurfaceColor(isDarkMode),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x.toInt()];
              final dur = Duration(seconds: entry.totalSeconds);
              final h = dur.inHours;
              final m = dur.inMinutes.remainder(60);
              final s = dur.inSeconds.remainder(60);
              String text;
              if (h > 0) {
                text = '${h}h ${m}m';
              } else if (m > 0) {
                text = '${m}m ${s}s';
              } else {
                text = '${s}s';
              }
              return BarTooltipItem(
                text,
                AppTextStyles.caption(isDarkMode: isDarkMode).copyWith(
                  fontWeight: AppTextStyles.weightSemiBold,
                  color: MainScreenColors.getTextColor(isDarkMode),
                ),
              );
            },
          ),
        ),
        titlesData: _buildTitlesData(isTime: true),
        gridData: _buildGridData(),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          final minutes = entries[i].totalSeconds / 60;
          return _buildBarGroup(i, minutes);
        }),
      ),
    );
  }

  Widget _buildSongsChart() {
    final maxCount = entries.fold<double>(
      0,
      (prev, e) =>
          e.playCount.toDouble() > prev ? e.playCount.toDouble() : prev,
    );
    final topY = maxCount == 0 ? 10.0 : (maxCount * 1.3).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: topY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                MainScreenColors.getSurfaceColor(isDarkMode),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = entries[group.x.toInt()];
              final count = entry.playCount;
              return BarTooltipItem(
                '$count song${count == 1 ? '' : 's'}',
                AppTextStyles.caption(isDarkMode: isDarkMode).copyWith(
                  fontWeight: AppTextStyles.weightSemiBold,
                  color: MainScreenColors.getTextColor(isDarkMode),
                ),
              );
            },
          ),
        ),
        titlesData: _buildTitlesData(isTime: false),
        gridData: _buildGridData(),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (i) {
          return _buildBarGroup(i, entries[i].playCount.toDouble());
        }),
      ),
    );
  }

  FlTitlesData _buildTitlesData({required bool isTime}) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: AppDimens.spacing4Xl,
          getTitlesWidget: (value, meta) {
            if (value == meta.max) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(right: AppDimens.spacingXs),
              child: Text(
                isTime ? '${value.toInt()}m' : '${value.toInt()}',
                style: AppTextStyles.finePrint(isDarkMode: isDarkMode).copyWith(
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.5),
                ),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx < 0 || idx >= entries.length) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(top: AppDimens.spacingS),
              child: Text(
                labelBuilder(entries[idx].dateKey),
                style: AppTextStyles.finePrint(isDarkMode: isDarkMode).copyWith(
                  fontWeight: AppTextStyles.weightMedium,
                  color: MainScreenColors.getTextColor(
                    isDarkMode,
                  ).withValues(alpha: 0.7),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) => FlLine(
        color: MainScreenColors.getTextColor(
          isDarkMode,
        ).withValues(alpha: 0.08),
        strokeWidth: AppDimens.borderWidthThin,
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int index, double value) {
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: value,
          width: entries.length <= 7 ? AppDimens.iconMdLg : AppDimens.iconXs,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimens.radiusS),
          ),
          gradient: LinearGradient(
            colors: [gradientBottom, gradientTop],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }
}
