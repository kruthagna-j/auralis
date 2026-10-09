import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:terminate_restart/terminate_restart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:provider/provider.dart';
import 'package:audio_session/audio_session.dart';
import 'package:media_kit/media_kit.dart';
import 'core/constants/app_text_styles.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/providers/download_provider.dart';
import 'core/providers/player_provider.dart';
import 'features/playlists/data/providers/playlist_album_library_provider.dart';
import 'features/home/data/providers/home_screen_provider.dart';
import 'core/providers/queued_provider.dart';
import 'core/providers/settings_provider.dart';
import 'features/trending/data/provider/trending_provider.dart';
import 'core/providers/favorite_artist_provider.dart';
import 'core/providers/favorite_song_provider.dart';
import 'features/library/data/providers/library_provider.dart';
import 'core/providers/lyrics_provider.dart';
import 'features/ota/data/providers/ota_provider.dart';
import 'core/providers/video_info_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/stats_provider.dart';
import 'core/services/intent_service.dart';
import 'core/services/download_notification_service.dart';
import 'core/services/smtc_service.dart';
import 'core/services/crash_log_service.dart';
import 'core/services/windows_file_service.dart';
import 'core/services/youtube_audio_service.dart';

String _ytMusicHlFromLanguage(String language) {
  switch (language) {
    case 'Hindi': return 'hi';
    case 'Spanish': return 'es';
    case 'French': return 'fr';
    case 'German': return 'de';
    case 'Russian': return 'ru';
    case 'Ukrainian': return 'uk';
    case 'Bengali': return 'bn';
    case 'Japanese': return 'ja';
    case 'Chinese': return 'zh';
    case 'Urdu': return 'ur';
    case 'Telugu': return 'te';
    case 'Tamil': return 'ta';
    case 'Marathi': return 'mr';
    case 'Turkish': return 'tr';
    case 'Gujarati': return 'gu';
    case 'Kannada': return 'kn';
    case 'Korean': return 'ko';
    case 'Indonesian': return 'id';
    case 'Portuguese': return 'pt';
    case 'Vietnamese': return 'vi';
    case 'Arabic': return 'ar';
    case 'English':
    default: return 'en';
  }
}

Future<void> main() async {
  final talker = TalkerFlutter.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    talker.handle(details.exception, details.stack ?? StackTrace.current, 'FlutterError.onError');
    FlutterError.presentError(details);
  };

  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      if (Platform.isAndroid || Platform.isIOS) {
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
      MediaKit.ensureInitialized();

      TerminateRestart.instance.initialize();
      final appSupportDir = await getApplicationSupportDirectory();
      final hiveDir = Directory('${appSupportDir.path}/auralis');
      if (!await hiveDir.exists()) await hiveDir.create(recursive: true);
      Hive.init(hiveDir.path);
      Hive.registerAdapter(SongInfoDTOAdapter());
      Hive.registerAdapter(ArtistDTOAdapter());
      Hive.registerAdapter(ThumbnailDTOAdapter());
      Hive.registerAdapter(HomeSectionDTOAdapter());
      Hive.registerAdapter(AlbumDetailedDTOAdapter());
      Hive.registerAdapter(PlaylistDetailedDTOAdapter());
      Hive.registerAdapter(ArtistBasicDTOAdapter());
      Hive.registerAdapter(ThumbnailFullDTOAdapter());

      final settingsProvider = SettingsProvider();
      GetIt.I.registerSingleton<SettingsProvider>(settingsProvider);
      GetIt.I.registerSingleton<YoutubeAudioService>(YoutubeAudioService());

      const hiveBoxNames = [
        'liked_songs', 'favorite_artists', 'audio_url_cache', 'saved_playlists',
        'saved_albums', 'created_playlists', 'playlist_songs', 'last_played',
        'queue_storage', 'video_info_cache', 'playback_stats', 'recent_playlists',
      ];

      await Hive.openBox<dynamic>('app_settings');
      await Future.wait([
        settingsProvider.loadSettings(),
        Future.wait(hiveBoxNames.map((name) => Hive.openBox<String>(name))),
      ]);

      final connectivityProvider = ConnectivityProvider();
      GetIt.I.registerSingleton<ConnectivityProvider>(connectivityProvider);
      GetIt.I.registerSingleton<Talker>(talker);

      final crashLogService = CrashLogService();
      await crashLogService.init();
      GetIt.I.registerSingleton<CrashLogService>(crashLogService);

      try {
        if (settingsProvider.loggingOnStartup) {
          crashLogService.startLogging();
          talker.info('Continuous logging started (startup setting enabled)');
        }
      } catch (_) {}

      FlutterError.onError = (FlutterErrorDetails details) {
        talker.handle(details.exception, details.stack ?? StackTrace.current, 'FlutterError.onError');
        try {
          GetIt.I<CrashLogService>().recordError(details.exception, details.stack ?? StackTrace.current, 'FlutterError.onError');
        } catch (_) {}
        FlutterError.presentError(details);
      };

      GetIt.I.registerSingleton<YoutubeExplode>(YoutubeExplode());

      final ytMusic = YTMusic();
      final ytMusicHl = _ytMusicHlFromLanguage(settingsProvider.language);
      try {
        await ytMusic.initialize(hl: ytMusicHl).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            talker.warning('YTMusic initialization timed out - continuing in offline mode');
            return ytMusic;
          },
        );
        talker.info('YTMusic initialized successfully (hl=$ytMusicHl)');
      } catch (e, st) {
        talker.error('YTMusic initialization failed: $e - continuing in offline mode');
        talker.handle(e, st, 'YTMusic initialization failed');
      }
      GetIt.I.registerSingleton<YTMusic>(ytMusic);
      GetIt.I.registerSingleton<VideoInfoProvider>(VideoInfoProvider());

      await EasyLocalization.ensureInitialized();

      if (Platform.isAndroid || Platform.isWindows || Platform.isLinux) {
        final notificationService = DownloadNotificationService();
        await notificationService.initialize();
      }

      if (Platform.isAndroid) {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      }
      if (Platform.isWindows) await SmtcService.ensureInitialized();
      await MetadataGod.initialize();

      final downloadProvider = DownloadProvider();
      final queueProvider = QueueProvider();
      final statsProvider = StatsProvider();

      talker.info('Auralis app starting');

      runApp(
        TalkerWrapper(
          talker: talker,
          options: const TalkerWrapperOptions(enableErrorAlerts: true),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: connectivityProvider),
              ChangeNotifierProvider(lazy: false, create: (_) => HomeScreenProvider()..initialize()),
              ChangeNotifierProvider(create: (_) => TrendingProvider()),
              ChangeNotifierProvider.value(value: queueProvider),
              ChangeNotifierProvider.value(value: downloadProvider),
              ChangeNotifierProvider.value(value: statsProvider),
              ChangeNotifierProvider(create: (_) => FavoriteSongProvider()),
              ChangeNotifierProvider(
                create: (context) => PlayerProvider(
                  Provider.of<QueueProvider>(context, listen: false),
                  Provider.of<DownloadProvider>(context, listen: false),
                  GetIt.I<VideoInfoProvider>(),
                  Provider.of<StatsProvider>(context, listen: false),
                  Provider.of<FavoriteSongProvider>(context, listen: false),
                ),
              ),
              ChangeNotifierProvider(lazy: false, create: (_) => PlaylistAlbumLibraryProvider()..loadAll()),
              ChangeNotifierProvider.value(value: settingsProvider),
              ChangeNotifierProvider(lazy: false, create: (_) => FavoriteArtistProvider()..loadFavoriteArtists()),
              ChangeNotifierProvider(
                create: (context) => LibraryProvider(
                  Provider.of<PlayerProvider>(context, listen: false),
                  Provider.of<DownloadProvider>(context, listen: false),
                  Provider.of<FavoriteSongProvider>(context, listen: false),
                  Provider.of<SettingsProvider>(context, listen: false),
                ),
              ),
              ChangeNotifierProvider(create: (context) => LyricsProvider(Provider.of<PlayerProvider>(context, listen: false))),
              ChangeNotifierProvider(create: (_) => OTAProvider()),
              ChangeNotifierProvider.value(value: GetIt.I<VideoInfoProvider>()),
            ],
            child: EasyLocalization(
              supportedLocales: const [
                Locale('en'), Locale('hi'), Locale('es'), Locale('fr'), Locale('de'), Locale('ru'),
                Locale('uk'), Locale('bn'), Locale('ja'), Locale('zh'), Locale('ur'), Locale('te'),
                Locale('ta'), Locale('mr'), Locale('tr'), Locale('gu'), Locale('kn'), Locale('ko'),
                Locale('id'), Locale('pt'), Locale('vi'), Locale('ar'),
              ],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: const AuralisApp(),
            ),
          ),
        ),
      );
    },
    (error, stackTrace) {
      talker.handle(error, stackTrace, 'Uncaught zone error');
      try {
        if (GetIt.I.isRegistered<CrashLogService>()) {
          GetIt.I<CrashLogService>().recordError(error, stackTrace, 'Uncaught zone error');
        }
      } catch (_) {}
    },
  );
}

class AuralisApp extends StatefulWidget {
  const AuralisApp({super.key});
  @override
  State<AuralisApp> createState() => _AuralisAppState();
}

class _AuralisAppState extends State<AuralisApp> with WidgetsBindingObserver {
  IntentService? _intentService;
  WindowsFileService? _windowsFileService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _intentService = IntentService(
        Provider.of<PlayerProvider>(context, listen: false),
        Provider.of<QueueProvider>(context, listen: false),
      );
      _intentService?.init();
    }
    if (Platform.isWindows) {
      _windowsFileService = WindowsFileService(Provider.of<PlayerProvider>(context, listen: false));
      WidgetsBinding.instance.addPostFrameCallback((_) => _windowsFileService?.init());
    }
  }

  @override
  void dispose() {
    _intentService?.dispose();
    _windowsFileService?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return MaterialApp(
      navigatorKey: settingsProvider.navigatorKey,
      navigatorObservers: [],
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Auralis',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      builder: (context, child) {
        final styledChild = AppTextStyles.appBuilder(context, child);
        return Stack(
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: GetIt.I<YoutubeAudioService>().buildHost(),
              ),
            ),
            styledChild,
          ],
        );
      },
      home: const SplashScreen(),
    );
  }
}
