import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:metadata_god/metadata_god.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/audio_url_service.dart';
import 'app_snackbar.dart';
import 'marquee_text.dart';
import '../../core/providers/player_provider.dart';
import '../../core/utils/content_router.dart';
import 'add_to_playlist_bottomsheet.dart';

class _LocalSongMeta {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final double? durationMs;
  final int? fileSize;
  final Uint8List? coverArt;
  final String? fileExtension;
  final int? fsSizeBytes;

  const _LocalSongMeta({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.durationMs,
    this.fileSize,
    this.coverArt,
    this.fileExtension,
    this.fsSizeBytes,
  });
}

class PlayerMoreSongBottomSheet extends StatefulWidget {
  const PlayerMoreSongBottomSheet({Key? key}) : super(key: key);

  @override
  _PlayerMoreSongBottomSheetState createState() =>
      _PlayerMoreSongBottomSheetState();
}

class _PlayerMoreSongBottomSheetState extends State<PlayerMoreSongBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  _LocalSongMeta? _localMeta;
  bool _loadingMeta = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: AppDimens.animDefault,
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLocalMeta());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocalMeta() async {
    final pp = Provider.of<PlayerProvider>(context, listen: false);
    final localSong = pp.currentLocalSong;
    if (localSong == null) return;

    final path = localSong['localPath'] as String?;
    if (path == null || path.isEmpty) return;

    setState(() => _loadingMeta = true);
    try {
      final metadata = await MetadataGod.readMetadata(file: path);

      int? fsSizeBytes;
      try {
        fsSizeBytes = (await File(path).stat()).size;
      } catch (_) {}

      Uint8List? coverArt;
      if (metadata.picture?.data != null) {
        coverArt = Uint8List.fromList(metadata.picture!.data);
      }

      final ext = path.contains('.')
          ? path.split('.').last.toUpperCase()
          : 'AUDIO';

      if (mounted) {
        setState(() {
          _localMeta = _LocalSongMeta(
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            albumArtist: metadata.albumArtist,
            genre: metadata.genre,
            year: metadata.year,
            trackNumber: metadata.trackNumber,
            trackTotal: metadata.trackTotal,
            discNumber: metadata.discNumber,
            discTotal: metadata.discTotal,
            durationMs: metadata.durationMs,
            fileSize: metadata.fileSize != null
                ? metadata.fileSize!.toInt()
                : null,
            coverArt: coverArt,
            fileExtension: ext,
            fsSizeBytes: fsSizeBytes,
          );
          _loadingMeta = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  String _fmtDuration(Duration? d) {
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  String _fmtMs(double? ms) {
    if (ms == null) return '—';
    return _fmtDuration(Duration(milliseconds: ms.round()));
  }

  String _fmtCount(int? count) {
    if (count == null || count == 0) return 'N/A';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '—';
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _fmtBytes(int? bytes) {
    if (bytes == null || bytes == 0) return '—';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      if (host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
      if (host.contains('youtube.com') || host.contains('music.youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) return v;
        final segs = uri.pathSegments;
        if (segs.isNotEmpty && segs.last.isNotEmpty) return segs.last;
      }
    } catch (_) {}
    return null;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.showSuccess(
      context,
      '$label copied to clipboard',
      duration: Duration(milliseconds: AppDimens.animLong.inMilliseconds * 2),
    );
  }

  Future<void> _shareSong(
    PlayerProvider pp,
    String shareText,
    String? youtubeLink,
  ) async {
    const appLink = 'https://github.com/kruthagna-j/auralis-app';
    try {
      final localSong = pp.currentLocalSong;
      if (localSong != null) {
        final path = localSong['localPath'] as String?;
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          await Share.shareXFiles([XFile(path)], text: shareText);
          return;
        }
        SharePlus.instance.share(ShareParams(text: shareText));
        return;
      }

      final currentSong = pp.currentSong;
      String? thumbUrl;
      if (currentSong != null && currentSong.thumbnails.isNotEmpty) {
        thumbUrl = currentSong.thumbnails.first.url;
      }
      if (thumbUrl != null && thumbUrl.startsWith('http')) {
        final res = await http.get(Uri.parse(thumbUrl));
        if (res.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/auralis_share.jpg');
          await file.writeAsBytes(res.bodyBytes);
          await Share.shareXFiles([
            XFile(file.path),
          ], text: '$shareText\n\nDownload Auralis: $appLink');
          return;
        }
      }
      SharePlus.instance.share(
        ShareParams(text: '$shareText\n\nDownload Auralis: $appLink'),
      );
    } catch (_) {
      SharePlus.instance.share(ShareParams(text: shareText));
    }
  }

  void _openArtistDetail(dynamic artist, PlayerProvider pp) {
    final song = pp.currentSong;
    if (artist?.id == null || (artist.id as String).isEmpty) return;
    final thumbUrl = song?.thumbnails.isNotEmpty == true
        ? song!.thumbnails.first.url
        : '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentRouter(
          content: ArtistDetailed(
            artistId: artist.id,
            name: artist.name,
            thumbnails: [ThumbnailFull(url: thumbUrl, width: 0, height: 0)],
            type: '',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final pp = Provider.of<PlayerProvider>(context, listen: false);
    final accentColor = settingsProvider.accentColor;

    final currentSong = pp.currentSong;
    final currentLocalSong = pp.currentLocalSong;
    final isLocalSong = currentLocalSong != null;

    String songTitle = 'Unknown Title';
    String songArtist = 'Unknown Artist';
    String? videoId;
    bool isJioSaavn = false;

    if (currentSong != null) {
      songTitle = currentSong.name;
      songArtist = currentSong.artists.isNotEmpty
          ? currentSong.artists.map((a) => a.name).join(', ')
          : 'Unknown Artist';
      videoId = currentSong.videoId;
      try {
        final cacheBox = Hive.box<String>('audio_url_cache');
        final cacheKeys = AudioUrlService.buildLookupCacheKeys(
          videoId: videoId,
          streamingQuality: settingsProvider.streamingQuality,
          jioSaavnEnabled: settingsProvider.jioSaavnEnabled,
        );

        for (final cacheKey in cacheKeys) {
          final cachedJson = cacheBox.get(cacheKey);
          if (cachedJson == null) continue;

          final data = json.decode(cachedJson) as Map<String, dynamic>;
          final source = AudioUrlService.normalizeProvider(
            data['source'] as String? ?? '',
          );
          final cachedUrl = data['url'] as String?;
          if (source == 'jiosaavn' ||
              (cachedUrl != null &&
                  (cachedUrl.contains('saavncdn.com') ||
                      cachedUrl.contains('jiosaavn')))) {
            isJioSaavn = true;
            break;
          }
        }
      } catch (_) {}
    } else if (currentLocalSong != null) {
      songTitle =
          _localMeta?.title ?? currentLocalSong['title'] ?? 'Unknown Title';
      songArtist =
          _localMeta?.artist ?? currentLocalSong['artist'] ?? 'Unknown Artist';
    }

    final youtubeLink = videoId != null
        ? 'https://www.youtube.com/watch?v=$videoId'
        : null;
    const appLink = 'https://github.com/kruthagna-j/auralis-app';
    final shareText = isLocalSong
        ? '🎵 Listening to "$songTitle" by $songArtist'
        : '🎵 Currently listening to "$songTitle" by $songArtist'
              '${youtubeLink != null ? '\n\n🔗 $youtubeLink' : ''}'
              '\n\nDownload Auralis: $appLink 🎶';

    final bgColor = MainScreenColors.getSurfaceColor(isDarkMode);
    final textColor = MainScreenColors.getTextColor(isDarkMode);

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, _) => Opacity(
        opacity: _fadeAnim.value,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * AppDimens.sheetHeightFactor,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimens.radiusFull),
                topRight: Radius.circular(AppDimens.radiusFull),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTopBar(textColor),

                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.paddingXl,
                      AppDimens.spacingLg,
                      AppDimens.paddingXl,
                      AppDimens.spacingXxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildAlbumArt(pp, isDarkMode, size.width, isLocalSong),
                        const SizedBox(height: AppDimens.spacingXxl),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  songTitle,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headingLg(
                                    isDarkMode: isDarkMode,
                                  ),
                                ),
                              ),
                              if (isJioSaavn) ...[
                                const SizedBox(width: 6),
                                _badge('320 HD', accentColor),
                              ],
                              if (isLocalSong &&
                                  _localMeta?.fileExtension != null) ...[
                                const SizedBox(width: 6),
                                _badge(_localMeta!.fileExtension!, accentColor),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimens.spacingSm),

                        _buildArtistSection(
                          pp,
                          isLocalSong,
                          isDarkMode,
                          size.width,
                          accentColor,
                        ),
                        const SizedBox(height: AppDimens.spacingXxl),

                        if (!isLocalSong && pp.currentVideoDetails != null) ...[
                          _buildOnlineStatsRow(
                            pp.currentVideoDetails!,
                            isDarkMode,
                            size.width,
                          ),
                          const SizedBox(height: AppDimens.spacingXxl),
                        ],

                        if (isLocalSong)
                          _buildLocalMetadataSection(
                            pp,
                            currentLocalSong,
                            isDarkMode,
                            accentColor,
                            textColor,
                            textColor.withValues(alpha: 0.55),
                            size.width,
                            shareText,
                          ),
                      ],
                    ),
                  ),
                ),

                if (!isLocalSong)
                  _buildActionBar(
                    isDarkMode: isDarkMode,
                    isLocalSong: isLocalSong,
                    accentColor: accentColor,
                    textColor: textColor,
                    bgColor: bgColor,
                    bottomPad: bottomPad,
                    pp: pp,
                    currentSong: currentSong,
                    currentLocalSong: currentLocalSong,
                    songTitle: songTitle,
                    songArtist: songArtist,
                    videoId: videoId,
                    youtubeLink: youtubeLink,
                    shareText: shareText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Container(
            width: AppDimens.dragHandleWidth,
            height: AppDimens.dragHandleHeight,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(
    PlayerProvider pp,
    bool isDarkMode,
    double sw,
    bool isLocalSong,
  ) {
    final artSize = sw < AppDimens.breakpointSmallMobile
        ? 140.0
        : sw < AppDimens.breakpointMobile
        ? 170.0
        : 200.0;
    final bg = MainScreenColors.getSurfaceColor(isDarkMode);
    final iconColor = MainScreenColors.getTextColor(
      isDarkMode,
    ).withValues(alpha: 0.22);

    Widget art;
    if (isLocalSong && _localMeta?.coverArt != null) {
      art = Image.memory(
        _localMeta!.coverArt!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(bg, iconColor, artSize),
      );
    } else if (!isLocalSong) {
      final song = pp.currentSong;
      final thumb = song?.thumbnails.isNotEmpty == true
          ? song!.thumbnails.first.url
          : '';
      final vid = song?.videoId;
      if (thumb.startsWith('http')) {
        art = CachedNetworkImage(
          imageUrl: vid != null
              ? 'https://img.youtube.com/vi/$vid/maxresdefault.jpg'
              : thumb,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(bg, iconColor, artSize),
          errorWidget: (_, __, ___) => _placeholder(bg, iconColor, artSize),
        );
      } else {
        art = _placeholder(bg, iconColor, artSize);
      }
    } else {
      art = _placeholder(bg, iconColor, artSize);
    }

    return Container(
      width: artSize,
      height: artSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
        child: art,
      ),
    );
  }

  Widget _placeholder(Color bg, Color iconColor, double size) => Container(
    color: bg,
    child: Icon(Icons.music_note_rounded, color: iconColor, size: size * 0.35),
  );

  Widget _buildArtistSection(
    PlayerProvider pp,
    bool isLocalSong,
    bool isDarkMode,
    double sw,
    Color accentColor,
  ) {
    if (!isLocalSong && pp.currentSong != null) {
      final artists = pp.currentSong!.artists;
      if (artists.isEmpty) {
        return Text(
          pp.currentArtist,
          style: AppTextStyles.settingsSubtitle(isDarkMode: isDarkMode),
        );
      }
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: artists.map<Widget>((artist) {
          final hasId = (artist.id).isNotEmpty;
          return InkWell(
            onTap: hasId ? () => _openArtistDetail(artist, pp) : null,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasId
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: hasId
                    ? Border.all(color: accentColor.withValues(alpha: 0.3))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[700],
                    child: const Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: sw * 0.35),
                    child: Text(
                      artist.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.settingsSubtitle(
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ),
                  if (hasId) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: accentColor.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final raw = pp.currentLocalSong?['artist'] as String? ?? pp.currentArtist;
    final artistList = raw
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: artistList.map<Widget>((a) {
        return Chip(
          avatar: const CircleAvatar(
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person_outline, size: 14, color: Colors.white70),
          ),
          label: Text(a, style: AppTextStyles.caption(isDarkMode: isDarkMode)),
          backgroundColor: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.08),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }

  Widget _buildOnlineStatsRow(dynamic vd, bool isDarkMode, double sw) {
    final iconSz = sw < 400 ? 14.0 : 15.0;
    final style = TextStyle(
      fontSize: iconSz * 0.86,
      color: Colors.white.withValues(alpha: 0.9),
      fontWeight: FontWeight.w500,
    );

    Widget cell(IconData icon, String val) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSz, color: Colors.white.withValues(alpha: 0.88)),
        SizedBox(width: iconSz * 0.3),
        Text(val, style: style),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: iconSz * 0.9,
          vertical: iconSz * 0.65,
        ),
        color: Colors.black.withValues(alpha: 0.36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            cell(Icons.access_time_rounded, _fmtDuration(vd.duration)),
            _vDivider(),
            cell(Icons.remove_red_eye_outlined, _fmtCount(vd.viewCount)),
            _vDivider(),
            cell(Icons.thumb_up_outlined, _fmtCount(vd.likeCount)),
            _vDivider(),
            cell(Icons.calendar_today_outlined, _fmtDate(vd.publishDate)),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    height: 16,
    width: 1,
    color: Colors.white.withValues(alpha: 0.18),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _buildLocalMetadataSection(
    PlayerProvider pp,
    Map<String, dynamic> ls,
    bool isDarkMode,
    Color accent,
    Color tc,
    Color sc,
    double sw,
    String shareText,
  ) {
    if (_loadingMeta) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent),
            ),
            const SizedBox(height: 12),
            Text(
              'Reading audio metadata…',
              style: AppTextStyles.caption(isDarkMode: isDarkMode),
            ),
          ],
        ),
      );
    }

    final meta = _localMeta;
    final localPath = ls['localPath'] as String? ?? '';

    final title = meta?.title ?? ls['title'] ?? '—';
    final artist = meta?.artist ?? ls['artist'] ?? '—';
    final album = meta?.album ?? ls['albumId'];
    final albumArtist = meta?.albumArtist;
    final genre = meta?.genre;
    final year = meta?.year;
    final trackNo = meta?.trackNumber;
    final trackTotal = meta?.trackTotal;
    final discNo = meta?.discNumber;
    final discTotal = meta?.discTotal;
    final durationSec = ls['duration'] as int? ?? 0;
    final durationDisplay = meta?.durationMs != null
        ? _fmtMs(meta!.durationMs)
        : _fmtDuration(Duration(seconds: durationSec));
    final fileSizeDisplay = _fmtBytes(meta?.fsSizeBytes ?? meta?.fileSize);
    final format = meta?.fileExtension ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHead('Track Info', Icons.music_note_rounded, accent),
        const SizedBox(height: AppDimens.spacingSm),
        _card(isDarkMode, [
          _row(Icons.title_rounded, 'Title', title, tc, sc),
          _divider(tc),
          _row(Icons.person_outline_rounded, 'Artist', artist, tc, sc),
          if (album != null && album.isNotEmpty) ...[
            _divider(tc),
            _row(Icons.album_outlined, 'Album', album, tc, sc),
          ],
          if (albumArtist != null && albumArtist.isNotEmpty) ...[
            _divider(tc),
            _row(
              Icons.people_outline_rounded,
              'Album Artist',
              albumArtist,
              tc,
              sc,
            ),
          ],
          if (genre != null && genre.isNotEmpty) ...[
            _divider(tc),
            _row(Icons.category_outlined, 'Genre', genre, tc, sc),
          ],
          if (year != null && year > 0) ...[
            _divider(tc),
            _row(Icons.calendar_month_outlined, 'Year', '$year', tc, sc),
          ],
        ]),

        if (trackNo != null || discNo != null) ...[
          const SizedBox(height: AppDimens.spacingXl),
          _sectionHead(
            'Track & Disc',
            Icons.format_list_numbered_rounded,
            accent,
          ),
          const SizedBox(height: AppDimens.spacingSm),
          _card(isDarkMode, [
            if (trackNo != null) ...[
              _row(
                Icons.numbers_rounded,
                'Track No.',
                trackTotal != null ? '$trackNo  /  $trackTotal' : '$trackNo',
                tc,
                sc,
              ),
            ],
            if (discNo != null) ...[
              if (trackNo != null) _divider(tc),
              _row(
                Icons.disc_full_outlined,
                'Disc No.',
                discTotal != null ? '$discNo  /  $discTotal' : '$discNo',
                tc,
                sc,
              ),
            ],
          ]),
        ],

        const SizedBox(height: AppDimens.spacingXl),
        _sectionHead('Audio & File', Icons.audiotrack_rounded, accent),
        const SizedBox(height: AppDimens.spacingSm),
        _card(isDarkMode, [
          _row(Icons.timer_outlined, 'Duration', durationDisplay, tc, sc),
          _divider(tc),
          _row(Icons.storage_outlined, 'File Size', fileSizeDisplay, tc, sc),
          _divider(tc),
          _row(Icons.audio_file_outlined, 'Format', format, tc, sc),
          if (localPath.isNotEmpty) ...[
            _divider(tc),
            _tappableRow(
              Icons.folder_open_outlined,
              'File Path',
              localPath,
              localPath,
              tc,
              sc,
              accent,
            ),
            _divider(tc),
            _actionRow(
              Icons.share_outlined,
              'Share',
              'Share file',
              tc,
              sc,
              accent,
              () => _shareSong(pp, shareText, null),
            ),
          ],
        ]),
        const SizedBox(height: AppDimens.spacingXl),
      ],
    );
  }

  Widget _sectionHead(String label, IconData icon, Color accent) => Row(
    children: [
      Icon(icon, size: 15, color: accent),
      const SizedBox(width: 7),
      Text(
        label,
        style: TextStyle(
          fontSize: AppTextStyles.fontSizeBody,
          fontWeight: FontWeight.w600,
          color: accent,
          letterSpacing: 0.35,
        ),
      ),
    ],
  );

  Widget _card(bool isDarkMode, List<Widget> children) {
    final bg = isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);
    final border = isDarkMode
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.08);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(children: children),
    );
  }

  Widget _divider(Color tc) =>
      Divider(color: tc.withValues(alpha: 0.07), height: 1, thickness: 1);

  Widget _row(IconData icon, String label, String value, Color tc, Color sc) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: sc),
            const SizedBox(width: 11),
            SizedBox(
              width: 98,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTextStyles.fontSizeBody2,
                  color: sc,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppTextStyles.fontSizeBody2,
                  color: tc,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );

  Widget _tappableRow(
    IconData icon,
    String label,
    String display,
    String full,
    Color tc,
    Color sc,
    Color accent,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: sc),
        const SizedBox(width: 11),
        SizedBox(
          width: 98,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTextStyles.fontSizeBody2,
              color: sc,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => _copyToClipboard(full, label),
            child: MarqueeText(
              text: display,
              style: TextStyle(
                fontSize: AppTextStyles.fontSizeBody2,
                color: accent,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: accent.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actionRow(
    IconData icon,
    String label,
    String value,
    Color tc,
    Color sc,
    Color accent,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: sc),
        const SizedBox(width: 11),
        SizedBox(
          width: 98,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppTextStyles.fontSizeBody2,
              color: sc,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: AppTextStyles.fontSizeBody2,
                color: accent,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: accent.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _badge(String text, Color accent) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: accent.withValues(alpha: 0.42)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: accent,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildActionBar({
    required bool isDarkMode,
    required bool isLocalSong,
    required Color accentColor,
    required Color textColor,
    required Color bgColor,
    required double bottomPad,
    required PlayerProvider pp,
    required dynamic currentSong,
    required Map<String, dynamic>? currentLocalSong,
    required String songTitle,
    required String songArtist,
    required String? videoId,
    required String? youtubeLink,
    required String shareText,
  }) {
    Widget btn({
      required IconData icon,
      required String label,
      required Color color,
      required bool enabled,
      required VoidCallback? onTap,
    }) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            onTap: enabled ? onTap : null,
            child: Container(
              width: AppDimens.iconStatus,
              height: AppDimens.iconStatus,
              decoration: BoxDecoration(
                color: color.withValues(alpha: enabled ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: color.withValues(alpha: enabled ? 0.26 : 0.09),
                ),
              ),
              child: Icon(
                icon,
                color: enabled ? color : color.withValues(alpha: 0.3),
                size: AppDimens.iconXxl,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingXs),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: enabled
                  ? textColor.withValues(alpha: 0.72)
                  : textColor.withValues(alpha: 0.28),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: textColor.withValues(alpha: 0.06)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.paddingXl,
        AppDimens.spacingMd,
        AppDimens.paddingXl,
        AppDimens.spacingXl + bottomPad,
      ),
      child: LayoutBuilder(
        builder: (ctx, cons) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(
                icon: Icons.play_arrow_rounded,
                label: 'YouTube',
                color: Colors.red,
                enabled: !isLocalSong,
                onTap: !isLocalSong
                    ? () async {
                        if (youtubeLink == null) return;
                        final uri = Uri.parse(youtubeLink);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      }
                    : null,
              ),
              const SizedBox(width: AppDimens.spacingLg),
              btn(
                icon: Icons.play_circle_outline_rounded,
                label: 'Music',
                color: Colors.redAccent,
                enabled: !isLocalSong,
                onTap: !isLocalSong
                    ? () async {
                        if (youtubeLink == null) return;
                        final id = videoId ?? _extractVideoId(youtubeLink);
                        if (id == null || id.isEmpty) return;
                        final uri = Uri.parse(
                          'https://music.youtube.com/watch?v=$id',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          final web = Uri.parse(youtubeLink);
                          if (await canLaunchUrl(web)) await launchUrl(web);
                        }
                      }
                    : null,
              ),
              const SizedBox(width: AppDimens.spacingLg),
              btn(
                icon: isLocalSong ? Icons.copy_outlined : Icons.link_rounded,
                label: 'Copy',
                color: accentColor,
                enabled: !isLocalSong,
                onTap: !isLocalSong
                    ? () => _copyToClipboard(
                        isLocalSong
                            ? (currentLocalSong?['localPath'] ?? songTitle)
                            : (youtubeLink ?? 'No link available'),
                        isLocalSong ? 'File path' : 'Song link',
                      )
                    : null,
              ),
              const SizedBox(width: AppDimens.spacingLg),
              btn(
                icon: Icons.share_outlined,
                label: 'Share',
                color: accentColor,
                enabled: true,
                onTap: () => _shareSong(pp, shareText, youtubeLink),
              ),
              const SizedBox(width: AppDimens.spacingLg),
              btn(
                icon: Icons.playlist_add_rounded,
                label: 'Add',
                color: accentColor,
                enabled: !isLocalSong,
                onTap: () {
                  final songData = {
                    'id': currentSong != null
                        ? currentSong.videoId
                        : (currentLocalSong?['id'] ?? ''),
                    'title': songTitle,
                    'artistId':
                        currentSong != null && currentSong.artists.isNotEmpty
                        ? (currentSong.artists.first.id ?? '')
                        : '',
                    'duration': currentSong != null
                        ? currentSong.duration.inSeconds
                        : (currentLocalSong?['duration'] ?? 0),
                    'thumbnail':
                        currentSong != null && currentSong.thumbnails.isNotEmpty
                        ? currentSong.thumbnails.first.url
                        : (currentLocalSong?['thumbnail'] ?? ''),
                    'artist': songArtist,
                  };
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    constraints: BoxConstraints(
                      maxHeight:
                          MediaQuery.of(context).size.height *
                          AppDimens.sheetHeightFactor,
                    ),
                    builder: (ctx) => SafeArea(
                      child: AddToPlaylistBottomSheet(song: songData),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
