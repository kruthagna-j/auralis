import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/player_ui.dart';

import '../../../../core/models/song_model.dart';
import '../../../../core/providers/lyrics_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../settings/presentation/screens/ai_api_config_screen.dart';

class LyricLine {
  final String text;
  final Duration? timestamp;

  LyricLine({required this.text, this.timestamp});
}

class LyricsDisplay extends StatefulWidget {
  final Stream<Duration> positionStream;
  final VoidCallback onClose;
  final Function(Duration) onSeek;

  const LyricsDisplay({
    Key? key,
    required this.positionStream,
    required this.onClose,
    required this.onSeek,
  }) : super(key: key);

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _parsedLyrics = [];
  List<GlobalKey> _lineKeys = [];
  int _currentLineIndex = 0;
  bool _userScrolling = false;
  Timer? _scrollTimer;
  bool _showPlainLyrics = false;
  StreamSubscription<Duration>? _positionSubscription;

  late LyricsProvider _lyricsProvider;
  late PlayerProvider _playerProvider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onUserScroll);

    _positionSubscription = widget.positionStream.listen((position) {
      if (!_userScrolling && !_showPlainLyrics) {
        _updateCurrentLine(position);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lyricsProvider = Provider.of<LyricsProvider>(context);
    _playerProvider = Provider.of<PlayerProvider>(context);

    _lyricsProvider.removeListener(_onLyricsProviderChanged);
    _lyricsProvider.addListener(_onLyricsProviderChanged);
    _playerProvider.removeListener(_onPlayerProviderChanged);
    _playerProvider.addListener(_onPlayerProviderChanged);

    _parseLyrics();
  }

  void _onLyricsProviderChanged() {
    _parseLyrics();
  }

  void _onPlayerProviderChanged() {
    _parseLyrics();
  }

  void _parseLyrics() {
    final lyricsResponse = _lyricsProvider.lyricsResponse;
    if (lyricsResponse?.lyrics != null) {
      if (lyricsResponse!.isSynced) {
        _parsedLyrics = _parseSyncedLyrics(lyricsResponse.lyrics!);
      } else {
        _parsedLyrics = lyricsResponse.lyrics!
            .split('\n')
            .map((line) => LyricLine(text: line))
            .toList();
      }
    } else {
      _parsedLyrics = [];
    }

    _lineKeys = List.generate(_parsedLyrics.length, (_) => GlobalKey());

    if (mounted) {
      setState(() {});
    }
  }

  List<LyricLine> _parseSyncedLyrics(String lyrics) {
    final lines = lyrics.split('\n');
    final parsedLines = <LyricLine>[];

    for (var line in lines) {
      final match = RegExp(
        r'\[(\d{2}):(\d{2})\.(\d{2})\](.*)',
      ).firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!) * 10;
        final text = match.group(4)!.trim();

        if (text.isNotEmpty) {
          parsedLines.add(
            LyricLine(
              text: text,
              timestamp: Duration(
                minutes: minutes,
                seconds: seconds,
                milliseconds: milliseconds,
              ),
            ),
          );
        }
      }
    }

    return parsedLines;
  }

  void _onUserScroll() {
    if (!_scrollController.position.isScrollingNotifier.value) {
      _userScrolling = true;
      _scrollTimer?.cancel();
      _scrollTimer = Timer(
        Duration(milliseconds: AppDimens.animLong.inMilliseconds * 2),
        () {
          _userScrolling = false;
        },
      );
    }
  }

  void _updateCurrentLine(Duration position) {
    final lyricsProvider = Provider.of<LyricsProvider>(context, listen: false);
    if (!(lyricsProvider.lyricsResponse?.isSynced ?? false) || _showPlainLyrics)
      return;

    int newLineIndex = _parsedLyrics.indexWhere(
      (line) => line.timestamp != null && line.timestamp! > position,
    );

    if (newLineIndex == -1) {
      newLineIndex = _parsedLyrics.length - 1;
    } else if (newLineIndex > 0) {
      newLineIndex--;
    }

    if (newLineIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newLineIndex;
      });

      if (!_userScrolling) {
        _scrollToCurrentLine();
      }
    }
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients &&
        _currentLineIndex < _parsedLyrics.length &&
        _currentLineIndex >= 0) {
      final key = _lineKeys[_currentLineIndex];

      void performScroll() {
        if (key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: AppDimens.animSmooth,
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
        }
      }

      if (key.currentContext != null) {
        performScroll();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) performScroll();
        });
      }
    }
  }

  void _togglePlainLyrics() {
    setState(() {
      _showPlainLyrics = !_showPlainLyrics;
    });

    if (!_showPlainLyrics) {
      _scrollToCurrentLine();
    }
  }

  void _seekToLine(int lineIndex) {
    if (_lyricsProvider.lyricsResponse!.isSynced &&
        lineIndex < _parsedLyrics.length &&
        _parsedLyrics[lineIndex].timestamp != null) {
      widget.onSeek(_parsedLyrics[lineIndex].timestamp!);
    }
  }

  String _formatLyricsError(String? error, String provider) {
    if (error == null || error.isEmpty) return 'Lyrics not found';
    if (provider.toLowerCase().contains('lrclib')) {
      final statusMatch = RegExp(r'status code of (\d{3})').firstMatch(error);
      if (statusMatch != null) {
        final code = statusMatch.group(1);
        if (code == '404') return 'Lyrics not found (404).';
        return 'Failed to load lyrics (HTTP $code).';
      }

      if (error.contains('DioException')) {
        return 'Network error while fetching lyrics (LRCLib).';
      }
      final single = error.replaceAll('\n', ' ').trim();
      final firstSentence = single.split('.').first;
      return firstSentence.length <= 120
          ? firstSentence
          : '${firstSentence.substring(0, 116)}...';
    }
    final single = error.replaceAll('\n', ' ').trim();
    return single.length <= 140 ? single : '${single.substring(0, 136)}...';
  }

  List<Widget> _buildLyricsLines() {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;
    List<Widget> lines = [];

    for (int i = 0; i < _parsedLyrics.length; i++) {
      final isCurrentLine = i == _currentLineIndex;

      lines.add(
        AnimatedContainer(
          key: _lineKeys[i],
          duration: AppDimens.animDefault,
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXl,
            vertical: AppDimens.spacingXs,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.paddingXl,
            vertical: AppDimens.spacingLg,
          ),
          decoration: null,
          child: GestureDetector(
            onTap: () => _seekToLine(i),
            child: AnimatedDefaultTextStyle(
              duration: AppDimens.animDefault,
              style: isCurrentLine
                  ? AppTextStyles.heading(
                      isDarkMode: true,
                      color: Colors.white,
                    ).copyWith(
                      height: AppTextStyles.lineHeightRelaxed,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: accentColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : AppTextStyles.subtitle(
                      isDarkMode: true,
                    ).copyWith(color: Colors.white.withValues(alpha: 0.5)),
              child: Text(_parsedLyrics[i].text, textAlign: TextAlign.center),
            ),
          ),
        ),
      );
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final accentColor = settingsProvider.accentColor;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong =
        playerProvider.currentSong ??
        (playerProvider.currentLocalSong != null
            ? SongInfo(
                videoId: playerProvider.currentLocalSong!['id'] ?? '',
                name:
                    playerProvider.currentLocalSong!['title'] ?? 'Unknown Song',
                artists: [
                  Artist(
                    name:
                        playerProvider.currentLocalSong!['artist'] ??
                        'Unknown Artist',
                    id: '',
                  ),
                ],
                thumbnails: [
                  Thumbnail(
                    url:
                        playerProvider.currentLocalSong!['thumbnail'] ??
                        'assets/default_artwork.png',
                    width: 0,
                    height: 0,
                  ),
                ],
                duration: Duration(
                  milliseconds:
                      playerProvider.currentLocalSong!['duration'] ?? 0,
                ),
              )
            : null);

    final mq = MediaQuery.of(context);
    final double navIconScale = mq.textScaleFactor > 1.0
        ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
        : 1.0;

    final hasPlayer =
        playerProvider.currentSong != null ||
        playerProvider.lastPlayedSong != null ||
        playerProvider.currentLocalSong != null;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimens.radiusXxxl),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.68),
                Colors.grey[900]!.withValues(alpha: 0.75),
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimens.radiusXxxl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: AppDimens.spacingSm,
                      bottom: AppDimens.spacingS,
                    ),
                    child: Container(
                      width: AppDimens.dragHandleWidth,
                      height: AppDimens.dragHandleHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.6),
                            accentColor.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        vertical: AppDimens.spacingSm,
                      ),
                      child: Consumer<SettingsProvider>(
                        builder: (context, settings, child) {
                          final isLocalSong =
                              playerProvider.currentLocalSong != null;
                          final currentProvider = settings.lyricsProvider;

                          List<String> availableProviders = ['LRCLib', 'AI'];
                          if (!isLocalSong) {
                            availableProviders = ['LRCLib', 'YT Music', 'AI'];
                          }

                          double highlightWidth = 0;
                          double highlightLeft = 0;
                          final double totalWidth = AppDimens.buttonWidthMedium;
                          double itemWidth =
                              totalWidth / availableProviders.length;

                          int selectedIndex = availableProviders.indexOf(
                            currentProvider,
                          );
                          if (selectedIndex == -1) {
                            selectedIndex = 0;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              settings.lyricsProvider = 'LRCLib';
                              _lyricsProvider.fetchLyricsForCurrentSong();
                            });
                          }

                          highlightWidth = itemWidth - AppDimens.spacingS;
                          highlightLeft =
                              (selectedIndex * itemWidth) + AppDimens.spacingXs;

                          final double providerTextScale =
                              mq.textScaleFactor > 1.0
                              ? (1.0 / mq.textScaleFactor)
                                    .clamp(0.70, 1.0)
                                    .toDouble()
                              : 1.0;

                          return Container(
                            width: totalWidth,
                            height: AppDimens.buttonSizeCompact,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey[800]!.withValues(alpha: 0.8),
                                  Colors.grey[900]!.withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusXxl,
                              ),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: AppDimens.borderWidthThin,
                              ),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: AppDimens.animSmooth,
                                  curve: Curves.elasticOut,
                                  left: highlightLeft,
                                  top: AppDimens.spacingXs,
                                  width: highlightWidth,
                                  child: Container(
                                    height: AppDimens.iconXl,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          accentColor,
                                          accentColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusMdLg,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.32,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Row(
                                    children: availableProviders.map((
                                      provider,
                                    ) {
                                      final isSelected =
                                          currentProvider == provider;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            final alreadyTried = _lyricsProvider
                                                .hasTriedProvider(provider);

                                            settings.lyricsProvider = provider;
                                            setState(() {});

                                            if (alreadyTried) {
                                              await _lyricsProvider
                                                  .loadCachedLyricsForProvider(
                                                    provider,
                                                  );
                                            } else {
                                              await _lyricsProvider
                                                  .fetchLyricsForCurrentSong();
                                            }
                                          },
                                          child: Center(
                                            child: Text(
                                              provider,
                                              textScaleFactor:
                                                  providerTextScale,
                                              style: isSelected
                                                  ? AppTextStyles.caption(
                                                      isDarkMode: true,
                                                      color: Colors.white,
                                                    ).copyWith(
                                                      fontWeight: AppTextStyles
                                                          .weightSemiBold,
                                                    )
                                                  : AppTextStyles.caption(
                                                      isDarkMode: true,
                                                    ).copyWith(
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: AppDimens.spacingSm),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: AppDimens.borderWidthThin,
                        ),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _showPlainLyrics
                              ? Icons.format_list_bulleted
                              : Icons.lyrics_outlined,
                          color: Colors.white,
                          size: AppDimens.iconSm,
                        ),
                        onPressed: _togglePlainLyrics,
                        padding: EdgeInsets.all(AppDimens.spacingS),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (_lyricsProvider.isLoading)
                          SizedBox.expand(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: accentColor,
                              ),
                            ),
                          )
                        else if (_lyricsProvider.lyricsResponse?.lyrics ==
                                null ||
                            _lyricsProvider.lyricsResponse!.lyrics!.isEmpty)
                          SizedBox.expand(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_off,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: AppDimens.iconHero,
                                  ),
                                  SizedBox(height: AppDimens.spacingLg),
                                  Text(
                                    _formatLyricsError(
                                      _lyricsProvider.error,
                                      settingsProvider.lyricsProvider,
                                    ),
                                    style: AppTextStyles.bodyLg(
                                      isDarkMode: true,
                                    ).copyWith(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: AppDimens.spacingSm),
                                  if (_lyricsProvider.error != null &&
                                      _lyricsProvider.error!.length > 120)
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: accentColor,
                                      ),
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Error details'),
                                          content: SingleChildScrollView(
                                            child: SelectableText(
                                              _lyricsProvider.error!,
                                              style:
                                                  AppTextStyles.finePrintBase()
                                                      .copyWith(
                                                        fontSize: AppTextStyles
                                                            .fontSizeXs,
                                                      ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Text(
                                                'Close',
                                                style: TextStyle(
                                                  color: accentColor,
                                                  fontWeight: AppTextStyles
                                                      .weightSemiBold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        'Show details',
                                        style:
                                            AppTextStyles.caption(
                                              isDarkMode: true,
                                            ).copyWith(
                                              color: accentColor,
                                              fontWeight:
                                                  AppTextStyles.weightSemiBold,
                                            ),
                                      ),
                                    ),
                                  Consumer<SettingsProvider>(
                                    builder: (context, settings, child) {
                                      final isAiProvider =
                                          settings.lyricsProvider == 'AI';
                                      final isApiKeyError =
                                          _lyricsProvider.error != null &&
                                          (_lyricsProvider.error!.contains(
                                                'API Key is not set',
                                              ) ||
                                              _lyricsProvider.error!.contains(
                                                'API Key cannot be empty',
                                              ));
                                      return Column(
                                        children: [
                                          Text(
                                            'from ${settings.lyricsProvider}',
                                            style:
                                                AppTextStyles.bodyMd(
                                                  isDarkMode: true,
                                                ).copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.6),
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (isAiProvider &&
                                              isApiKeyError) ...[
                                            SizedBox(
                                              height: AppDimens.spacingLg,
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const AiApiConfigScreen(),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.settings,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                'Configure AI API',
                                                style: AppTextStyles.button()
                                                    .copyWith(
                                                      color: Colors.white,
                                                      fontWeight: AppTextStyles
                                                          .weightBold,
                                                    ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentColor,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      AppDimens.paddingXl,
                                                  vertical: AppDimens.paddingMd,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppDimens.radiusLg,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            child: _showPlainLyrics
                                ? SingleChildScrollView(
                                    padding: EdgeInsets.all(
                                      AppDimens.paddingXxl,
                                    ),
                                    child: Text(
                                      _lyricsProvider.lyricsResponse!.lyrics!,
                                      style:
                                          AppTextStyles.bodyLg(
                                            isDarkMode: true,
                                          ).copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            height:
                                                AppTextStyles.lineHeightRelaxed,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : SingleChildScrollView(
                                    controller: _scrollController,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(height: mq.size.height / 2),
                                        ..._buildLyricsLines(),
                                        SizedBox(height: mq.size.height / 2),
                                      ],
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),

                  if (hasPlayer)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).appBarTheme.backgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          height: AppDimens.miniPlayerHeight * navIconScale,
                          child: PlayerUI(
                            showFullScreen: false,
                            isEmbedded: true,
                            onMinimize: () {},
                            onExpand: () => widget.onClose(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                top: AppDimens.spacingS,
                left: AppDimens.spacingSm,
                child: SafeArea(
                  child: IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: AppDimens.iconSm,
                    ),
                    onPressed: () async {
                      setState(() {});
                      await _lyricsProvider.fetchLyricsForCurrentSong(
                        forceRefresh: true,
                      );
                    },
                    padding: EdgeInsets.all(AppDimens.spacingS),
                  ),
                ),
              ),
              Positioned(
                top: AppDimens.spacingS,
                right: AppDimens.spacingSm,
                child: SafeArea(
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: AppDimens.iconSm,
                    ),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.all(AppDimens.spacingS),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    _scrollTimer?.cancel();
    _positionSubscription?.cancel();
    _lyricsProvider.removeListener(_onLyricsProviderChanged);
    _playerProvider.removeListener(_onPlayerProviderChanged);
    super.dispose();
  }
}
