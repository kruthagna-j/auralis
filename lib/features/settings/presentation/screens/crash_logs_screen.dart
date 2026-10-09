import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/crash_log_service.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/components/app_snackbar.dart';

class CrashLogsScreen extends StatefulWidget {
  const CrashLogsScreen({Key? key}) : super(key: key);

  @override
  State<CrashLogsScreen> createState() => _CrashLogsScreenState();
}

class _CrashLogsScreenState extends State<CrashLogsScreen> {
  bool _loading = true;
  List<String> _channels = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      _channels = await GetIt.I<CrashLogService>().listLogChannels();
    } catch (_) {
      _channels = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleLogging() async {
    final service = GetIt.I<CrashLogService>();
    if (service.isLoggingActive) {
      service.stopLogging();
    } else {
      service.startLogging();
    }
    setState(() {});
  }

  void _openLogViewer(String channel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => LogViewerScreen(channel: channel)),
    );
  }

  Future<void> _shareChannel(String channel) async {
    await GetIt.I<CrashLogService>().shareLogs(context, channel: channel);
  }

  Future<void> _clearChannel(String channel) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDarkMode = settings.themeMode == ThemeMode.dark;
    final accentColor = settings.accentColor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        title: Text(
          'clear_logs'.tr(args: [channel]),
          style: AppTextStyles.titleLg(isDarkMode: isDarkMode),
        ),
        content: Text(
          'clear_logs_message'.tr(args: [channel]),
          style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(
              'cancel'.tr(),
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'confirm_button'.tr(),
              style: AppTextStyles.bodyMd(
                isDarkMode: isDarkMode,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await GetIt.I<CrashLogService>().clearLogs(channel: channel);
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'crash_logs_cleared_success'.tr(),
          accentColor: accentColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final logService = GetIt.I<CrashLogService>();

    return Selector<SettingsProvider, ({bool isDarkMode, Color accentColor})>(
      selector: (context, settingsProvider) => (
        isDarkMode: settingsProvider.themeMode == ThemeMode.dark,
        accentColor: settingsProvider.accentColor,
      ),
      builder: (context, themeData, child) {
        return Scaffold(
          backgroundColor: themeData.isDarkMode
              ? MainScreenColors.darkBackgroundColor
              : MainScreenColors.lightBackgroundColor,
          appBar: AppBar(
            backgroundColor: themeData.isDarkMode
                ? Colors.transparent
                : MainScreenColors.getSurfaceColor(false),
            elevation: 0,
            title: Text(
              'crash_logs_title'.tr(),
              style: AppTextStyles.headingLg(isDarkMode: themeData.isDarkMode),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: MainScreenColors.getTextColor(themeData.isDarkMode),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.delete_forever,
                  color: MainScreenColors.getTextColor(themeData.isDarkMode),
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: themeData.isDarkMode
                          ? MainScreenColors.darkSurfaceColor
                          : MainScreenColors.lightSurfaceColor,
                      title: Text(
                        'clear_all_logs'.tr(),
                        style: AppTextStyles.titleLg(
                          isDarkMode: themeData.isDarkMode,
                        ),
                      ),
                      content: Text(
                        'clear_all_logs_message'.tr(),
                        style: AppTextStyles.bodyMd(
                          isDarkMode: themeData.isDarkMode,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: Text(
                            'cancel'.tr(),
                            style: AppTextStyles.bodyMd(
                              isDarkMode: themeData.isDarkMode,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            'confirm_button'.tr(),
                            style: AppTextStyles.bodyMd(
                              isDarkMode: themeData.isDarkMode,
                              color: themeData.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await logService.clearLogs();
                    await _reload();
                    if (mounted) {
                      AppSnackBar.showSuccess(
                        context,
                        'crash_logs_cleared_success'.tr(),
                        accentColor: themeData.accentColor,
                      );
                    }
                  }
                },
                tooltip: 'clear'.tr(),
              ),
            ],
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: themeData.accentColor,
                  ),
                )
              : RefreshIndicator(
                  color: themeData.accentColor,
                  onRefresh: _reload,
                  child: ListView(
                    padding: EdgeInsets.all(AppDimens.paddingLg),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: themeData.isDarkMode
                              ? MainScreenColors.darkSurfaceColor
                              : MainScreenColors.lightSurfaceColor,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                          border: Border.all(
                            color: themeData.isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.06),
                            width: AppDimens.borderWidthThin,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(AppDimens.paddingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'start_logging'.tr(),
                                    style: AppTextStyles.subtitle(
                                      isDarkMode: themeData.isDarkMode,
                                    ),
                                  ),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: logService.loggingActive,
                                    builder: (context, active, child) {
                                      return ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: active
                                              ? Colors.red
                                              : themeData.accentColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusSm,
                                            ),
                                          ),
                                        ),
                                        icon: Icon(
                                          active
                                              ? Icons.stop
                                              : Icons.play_arrow,
                                          size: AppDimens.iconXs,
                                        ),
                                        label: Text(
                                          active
                                              ? 'stop_logging'.tr()
                                              : 'start_logging'.tr(),
                                          style: AppTextStyles.bodyMd(
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: _toggleLogging,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: AppDimens.spacingMd),
                              Material(
                                color: Colors.transparent,
                                child: SwitchListTile.adaptive(
                                  value: settings.loggingOnStartup,
                                  activeColor: themeData.accentColor,
                                  onChanged: (v) {
                                    settings.loggingOnStartup = v;
                                    if (v) {
                                      GetIt.I<CrashLogService>().startLogging();
                                    } else {
                                      GetIt.I<CrashLogService>().stopLogging();
                                    }
                                  },
                                  title: Text(
                                    'start_logging_on_startup'.tr(),
                                    style: AppTextStyles.bodyMd(
                                      isDarkMode: themeData.isDarkMode,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              SizedBox(height: AppDimens.spacingSm),
                              Text(
                                'logging_status'.tr() +
                                    ': ' +
                                    (logService.isLoggingActive
                                        ? 'logging_active'.tr()
                                        : 'logging_inactive'.tr()),
                                style:
                                    AppTextStyles.body2(
                                      isDarkMode: themeData.isDarkMode,
                                    ).copyWith(
                                      color: logService.isLoggingActive
                                          ? themeData.accentColor
                                          : MainScreenColors.getTextColor(
                                              themeData.isDarkMode,
                                            ).withValues(alpha: 0.7),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: AppDimens.spacingXxl),
                      Text(
                        'available_logs'.tr(),
                        style: AppTextStyles.subtitle(
                          isDarkMode: themeData.isDarkMode,
                        ),
                      ),
                      SizedBox(height: AppDimens.spacingMd),

                      ..._channels.map(
                        (ch) => Container(
                          margin: EdgeInsets.only(bottom: AppDimens.spacingSm),
                          decoration: BoxDecoration(
                            color: themeData.isDarkMode
                                ? MainScreenColors.darkSurfaceColor
                                : MainScreenColors.lightSurfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusLg,
                            ),
                            border: Border.all(
                              color: themeData.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: AppDimens.borderWidthThin,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingLg,
                                vertical: AppDimens.paddingSm,
                              ),
                              leading: Icon(
                                Icons.insert_drive_file,
                                color: themeData.accentColor,
                                size: AppDimens.iconLg,
                              ),
                              title: Text(
                                ch.toUpperCase(),
                                style: AppTextStyles.subtitle(
                                  isDarkMode: themeData.isDarkMode,
                                ),
                              ),
                              subtitle: FutureBuilder<String>(
                                future: GetIt.I<CrashLogService>().readLog(
                                  ch,
                                  tail: 120,
                                ),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return Text(
                                      '...',
                                      style: AppTextStyles.body2(
                                        isDarkMode: themeData.isDarkMode,
                                      ),
                                    );
                                  }
                                  final s = snap.data ?? '';
                                  if (s.isEmpty) {
                                    return Text(
                                      'no_logs_available'.tr(),
                                      style:
                                          AppTextStyles.body2(
                                            isDarkMode: themeData.isDarkMode,
                                          ).copyWith(
                                            color: MainScreenColors.getTextColor(
                                              themeData.isDarkMode,
                                            ).withValues(alpha: 0.5),
                                          ),
                                    );
                                  }
                                  return Text(
                                    s
                                        .replaceAll('\n', ' ')
                                        .replaceAll(RegExp('\\s+'), ' '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        AppTextStyles.body2(
                                          isDarkMode: themeData.isDarkMode,
                                        ).copyWith(
                                          color: MainScreenColors.getTextColor(
                                            themeData.isDarkMode,
                                          ).withValues(alpha: 0.7),
                                        ),
                                  );
                                },
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: MainScreenColors.getTextColor(
                                    themeData.isDarkMode,
                                  ),
                                ),
                                color: themeData.isDarkMode
                                    ? MainScreenColors.darkSurfaceColor
                                    : MainScreenColors.lightSurfaceColor,
                                onSelected: (v) async {
                                  if (v == 'view') _openLogViewer(ch);
                                  if (v == 'share') await _shareChannel(ch);
                                  if (v == 'clear') await _clearChannel(ch);
                                },
                                itemBuilder: (c) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Text(
                                      'view_logs'.tr(),
                                      style: AppTextStyles.bodyMd(
                                        isDarkMode: themeData.isDarkMode,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'share',
                                    child: Text(
                                      'share'.tr(),
                                      style: AppTextStyles.bodyMd(
                                        isDarkMode: themeData.isDarkMode,
                                      ),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'clear',
                                    child: Text(
                                      'clear'.tr(),
                                      style: AppTextStyles.bodyMd(
                                        isDarkMode: themeData.isDarkMode,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openLogViewer(ch),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class LogViewerScreen extends StatefulWidget {
  final String channel;
  const LogViewerScreen({Key? key, required this.channel}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _content = '';
  bool _loading = true;
  bool _searchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  int _currentMatchIndex = 0;
  List<int> _matchPositions = [];

  static const double _lineHeight = 18.0;
  static const double _topPadding = 28.0;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_matchPositions.isEmpty || !_scrollController.hasClients) return;

      final matchPos = _matchPositions[_currentMatchIndex];
      if (!mounted) return;

      final screenWidth = MediaQuery.of(context).size.width;
      final textWidth =
          screenWidth -
          (AppDimens.paddingLg * 2) -
          (AppDimens.paddingMd * 2) -
          (AppDimens.borderWidthThin * 2);

      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final isDarkMode = settings.themeMode == ThemeMode.dark;
      final baseTextStyle = TextStyle(
        fontFamily: 'monospace',
        fontSize: AppTextStyles.fontSizeCaption,
        color: MainScreenColors.getTextColor(isDarkMode),
      );

      final textSpan = _searchQuery.isNotEmpty
          ? _buildHighlightedSpan(
              content: _content,
              query: _searchQuery,
              baseStyle: baseTextStyle,
              matchBg: Colors.transparent,
              currentMatchBg: Colors.transparent,
            )
          : TextSpan(text: _content, style: baseTextStyle);

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout(maxWidth: textWidth);

      final offset = textPainter.getOffsetForCaret(
        TextPosition(offset: matchPos),
        Rect.zero,
      );

      final targetTop = _topPadding + offset.dy;
      final viewportHeight = _scrollController.position.viewportDimension;
      final maxExtent = _scrollController.position.maxScrollExtent;

      final desired = (targetTop - viewportHeight / 2 + _lineHeight / 2).clamp(
        0.0,
        maxExtent,
      );

      _scrollController.animateTo(
        desired,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onSearchChanged() {
    final q = _searchController.text;
    final positions = _findMatches(q);
    setState(() {
      _searchQuery = q;
      _matchPositions = positions;
      _currentMatchIndex = 0;
    });
    _scrollToCurrentMatch();
  }

  List<int> _findMatches(String query) {
    if (query.isEmpty || _content.isEmpty) return [];
    final lower = _content.toLowerCase();
    final lowerQ = query.toLowerCase();
    final result = <int>[];
    int start = 0;
    while (true) {
      final i = lower.indexOf(lowerQ, start);
      if (i == -1) break;
      result.add(i);
      start = i + 1;
    }
    return result;
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_matchPositions.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchPositions.length) %
          _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _toggleSearch() {
    setState(() {
      if (_searchMode) {
        _searchMode = false;
        _searchController.clear();
        _searchQuery = '';
        _matchPositions = [];
        _currentMatchIndex = 0;
      } else {
        _searchMode = true;
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _content = await GetIt.I<CrashLogService>().readLog(
        widget.channel,
        tail: 20000,
      );
    } catch (_) {
      _content = '';
    }
    setState(() => _loading = false);
  }

  TextSpan _buildHighlightedSpan({
    required String content,
    required String query,
    required TextStyle baseStyle,
    required Color matchBg,
    required Color currentMatchBg,
  }) {
    if (query.isEmpty) return TextSpan(text: content, style: baseStyle);

    final spans = <InlineSpan>[];
    final lc = content.toLowerCase();
    final lq = query.toLowerCase();
    int start = 0;
    int mi = 0;

    while (true) {
      final idx = lc.indexOf(lq, start);
      if (idx == -1) {
        if (start < content.length) {
          spans.add(TextSpan(text: content.substring(start), style: baseStyle));
        }
        break;
      }
      if (idx > start) {
        spans.add(
          TextSpan(text: content.substring(start, idx), style: baseStyle),
        );
      }
      final isCurrent = mi == _currentMatchIndex;
      spans.add(
        TextSpan(
          text: content.substring(idx, idx + query.length),
          style: baseStyle.copyWith(
            backgroundColor: isCurrent ? currentMatchBg : matchBg,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      mi++;
      start = idx + query.length;
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, ({bool isDarkMode, Color accentColor})>(
      selector: (context, settingsProvider) => (
        isDarkMode: settingsProvider.themeMode == ThemeMode.dark,
        accentColor: settingsProvider.accentColor,
      ),
      builder: (context, themeData, child) {
        final baseTextStyle = TextStyle(
          fontFamily: 'monospace',
          fontSize: AppTextStyles.fontSizeCaption,
          color: MainScreenColors.getTextColor(themeData.isDarkMode),
        );

        return Scaffold(
          backgroundColor: themeData.isDarkMode
              ? MainScreenColors.darkBackgroundColor
              : MainScreenColors.lightBackgroundColor,
          appBar: AppBar(
            backgroundColor: themeData.isDarkMode
                ? Colors.transparent
                : MainScreenColors.getSurfaceColor(false),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: MainScreenColors.getTextColor(themeData.isDarkMode),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: _searchMode
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: AppTextStyles.bodyMd(
                      isDarkMode: themeData.isDarkMode,
                    ),
                    decoration: InputDecoration(
                      hintText: 'search_logs'.tr(),
                      hintStyle:
                          AppTextStyles.bodyMd(
                            isDarkMode: themeData.isDarkMode,
                          ).copyWith(
                            color: MainScreenColors.getTextColor(
                              themeData.isDarkMode,
                            ).withValues(alpha: 0.4),
                          ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  )
                : Text(
                    '${widget.channel.toUpperCase()} ${'logs'.tr()}',
                    style: AppTextStyles.headingLg(
                      isDarkMode: themeData.isDarkMode,
                    ),
                  ),
            actions: [
              if (_searchMode && _matchPositions.isNotEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${_currentMatchIndex + 1}/${_matchPositions.length}',
                      style: AppTextStyles.body2(
                        isDarkMode: themeData.isDarkMode,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    color: MainScreenColors.getTextColor(themeData.isDarkMode),
                  ),
                  onPressed: _prevMatch,
                  tooltip: 'previous_match'.tr(),
                ),
                IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: MainScreenColors.getTextColor(themeData.isDarkMode),
                  ),
                  onPressed: _nextMatch,
                  tooltip: 'next_match'.tr(),
                ),
              ],
              if (_searchMode &&
                  _searchQuery.isNotEmpty &&
                  _matchPositions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'no_matches'.tr(),
                      style: AppTextStyles.body2(
                        isDarkMode: themeData.isDarkMode,
                      ).copyWith(color: Colors.red.shade400),
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _searchMode ? Icons.search_off : Icons.search,
                  color: MainScreenColors.getTextColor(themeData.isDarkMode),
                ),
                onPressed: _toggleSearch,
                tooltip: _searchMode ? 'close_search'.tr() : 'search'.tr(),
              ),
              if (!_searchMode) ...[
                IconButton(
                  onPressed: () => GetIt.I<CrashLogService>().shareLogs(
                    context,
                    channel: widget.channel,
                  ),
                  icon: Icon(
                    Icons.share,
                    color: MainScreenColors.getTextColor(themeData.isDarkMode),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await GetIt.I<CrashLogService>().clearLogs(
                      channel: widget.channel,
                    );
                    await _load();
                  },
                  icon: Icon(
                    Icons.delete_forever,
                    color: MainScreenColors.getTextColor(themeData.isDarkMode),
                  ),
                ),
              ],
            ],
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: themeData.accentColor,
                  ),
                )
              : (_content.trim().isEmpty
                    ? Center(
                        child: Text(
                          'no_logs_available'.tr(),
                          style: AppTextStyles.bodyMd(
                            isDarkMode: themeData.isDarkMode,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.all(AppDimens.paddingLg),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppDimens.paddingMd),
                          decoration: BoxDecoration(
                            color: themeData.isDarkMode
                                ? MainScreenColors.darkSurfaceColor
                                : MainScreenColors.lightSurfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusSm,
                            ),
                            border: Border.all(
                              color: themeData.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
                              width: AppDimens.borderWidthThin,
                            ),
                          ),
                          child: _searchQuery.isNotEmpty
                              ? SelectableText.rich(
                                  _buildHighlightedSpan(
                                    content: _content,
                                    query: _searchQuery,
                                    baseStyle: baseTextStyle,
                                    matchBg: themeData.accentColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    currentMatchBg: themeData.accentColor,
                                  ),
                                )
                              : SelectableText(_content, style: baseTextStyle),
                        ),
                      )),
        );
      },
    );
  }
}
