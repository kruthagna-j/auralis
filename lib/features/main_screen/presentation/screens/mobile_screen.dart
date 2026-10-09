import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/audio_output_bottomsheet.dart';

import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/ota_model.dart';
import '../../../ota/data/providers/ota_provider.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../player/presentation/screens/player_ui.dart';
import 'desktop_screen.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../widgets/mobile_drawer.dart';
import '../../../ota/presentation/widgets/ota_bottomsheet.dart';
import 'full_player_screen.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      if (settingsProvider.updateCheckEnabled) {
        Provider.of<OTAProvider>(context, listen: false).checkForUpdates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OTAProvider>(
      builder: (context, otaProvider, child) {
        if (otaProvider.hasUpdate &&
            otaProvider.updateInfo != null &&
            !otaProvider.isUpdateUIShown &&
            !otaProvider.isOTAScreenActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            otaProvider.setUpdateUIShown(true);
            _showOTABottomSheet(context, otaProvider.updateInfo!);
          });
        }

        return Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final accentColor = settingsProvider.accentColor;
            final theme = settingsProvider.themeMode == ThemeMode.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme;

            final mq = MediaQuery.of(context);
            final double navIconScale = mq.textScaleFactor > 1.0
                ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
                : 1.0;
            final double navTextCap = mq.textScaleFactor > 1.0
                ? 1.0
                : mq.textScaleFactor;
            final double navIconSize = AppDimens.iconXl * navIconScale;

            return Theme(
              data: theme,
              child: SafeArea(
                top: false,
                child: PersistentTabView(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  controller: _controller,
                  tabs: [
                    PersistentTabConfig(
                      screen: _TabWrapper(
                        key: const ValueKey('home_tab'),
                        child: const HomeScreen(),
                        titleKey: 'home',
                        isHome: true,
                        onSearchTap: () => _controller.jumpToTab(1),
                      ),
                      item: ItemConfig(
                        icon: Icon(Icons.home_rounded, size: navIconSize),
                        title: 'home'.tr(),
                        activeForegroundColor: accentColor,
                        inactiveForegroundColor:
                            theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            Colors.grey,
                      ),
                    ),
                    PersistentTabConfig(
                      screen: const _TabWrapper(
                        key: ValueKey('search_tab'),
                        child: SearchScreen(),
                        titleKey: 'search',
                        isHome: false,
                        showAppBar: false,
                      ),
                      item: ItemConfig(
                        icon: Icon(Icons.search_rounded, size: navIconSize),
                        title: 'search'.tr(),
                        activeForegroundColor: accentColor,
                        inactiveForegroundColor:
                            theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            Colors.grey,
                      ),
                    ),
                    PersistentTabConfig(
                      screen: const _TabWrapper(
                        key: ValueKey('playlists_tab'),
                        child: PlaylistScreen(),
                        titleKey: 'playlists',
                        isHome: false,
                      ),
                      item: ItemConfig(
                        icon: Icon(
                          Icons.playlist_play_rounded,
                          size: navIconSize,
                        ),
                        title: 'playlists'.tr(),
                        activeForegroundColor: accentColor,
                        inactiveForegroundColor:
                            theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            Colors.grey,
                      ),
                    ),
                    PersistentTabConfig(
                      screen: const _TabWrapper(
                        key: ValueKey('library_tab'),
                        child: LibraryScreen(),
                        titleKey: 'library',
                        isHome: false,
                      ),
                      item: ItemConfig(
                        icon: Icon(
                          Icons.library_music_rounded,
                          size: navIconSize,
                        ),
                        title: 'library'.tr(),
                        activeForegroundColor: accentColor,
                        inactiveForegroundColor:
                            theme.textTheme.bodyLarge?.color?.withValues(
                              alpha: 0.6,
                            ) ??
                            Colors.grey,
                      ),
                    ),
                  ],
                  navBarBuilder: (navBarConfig) => Consumer<PlayerProvider>(
                    builder: (context, playerProvider, child) {
                      final hasPlayer =
                          playerProvider.currentSong != null ||
                          playerProvider.lastPlayedSong != null ||
                          playerProvider.currentLocalSong != null;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasPlayer)
                            Container(
                              decoration: BoxDecoration(
                                color: theme.appBarTheme.backgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppDimens.radiusMd),
                                ),
                              ),
                              child: SizedBox(
                                height:
                                    AppDimens.miniPlayerHeight * navIconScale,
                                child: PlayerUI(
                                  showFullScreen: false,
                                  isEmbedded: true,
                                  onMinimize: () {},
                                  onExpand: () =>
                                      _showFullPlayerBottomSheet(context),
                                ),
                              ),
                            ),
                          MediaQuery(
                            data: mq.copyWith(textScaleFactor: navTextCap),
                            child: MediaQuery.removePadding(
                              context: context,
                              removeBottom: true,
                              child: Style2BottomNavBar(
                                navBarConfig: navBarConfig,
                                navBarDecoration: NavBarDecoration(
                                  color: theme.appBarTheme.backgroundColor,
                                  borderRadius: BorderRadius.zero,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppDimens.spacingSmMd,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                itemAnimationProperties: const ItemAnimation(
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOTABottomSheet(BuildContext context, OTAUpdateInfo updateInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OTABottomSheet(updateInfo: updateInfo),
    );
  }

  void _showFullPlayerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) {
        return _MobileFullPlayerResponsiveWrapper(
          child: const FullPlayerScreen(),
          onSwitchToDesktop: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (MediaQuery.of(context).size.width >= 600) {
                Navigator.of(context, rootNavigator: true).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const FullPlayerScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 350),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 300,
                    ),
                  ),
                );
              }
            });
          },
        );
      },
    );
  }
}

class _MobileFullPlayerResponsiveWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwitchToDesktop;

  const _MobileFullPlayerResponsiveWrapper({
    Key? key,
    required this.child,
    required this.onSwitchToDesktop,
  }) : super(key: key);

  @override
  State<_MobileFullPlayerResponsiveWrapper> createState() =>
      _MobileFullPlayerResponsiveWrapperState();
}

class _MobileFullPlayerResponsiveWrapperState
    extends State<_MobileFullPlayerResponsiveWrapper>
    with WidgetsBindingObserver {
  bool _hasSwitched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    final width = MediaQuery.of(context).size.width;
    if (!_hasSwitched && width >= 600) {
      _hasSwitched = true;
      widget.onSwitchToDesktop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TabWrapper extends StatelessWidget {
  final Widget child;
  final String titleKey;
  final bool isHome;
  final bool showAppBar;
  final VoidCallback? onSearchTap;

  const _TabWrapper({
    super.key,
    required this.child,
    required this.titleKey,
    required this.isHome,
    this.showAppBar = true,
    this.onSearchTap,
  });

  Future<void> _showAudioOutputSheet(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;
    await showAudioOutputBottomSheet(
      context,
      isDarkMode: isDarkMode,
      accentColor: accentColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final mq = MediaQuery.of(context);
    final double _appBarIconScale = mq.textScaleFactor > 1.0
        ? (1.0 / mq.textScaleFactor).clamp(0.75, 1.0).toDouble()
        : 1.0;
    final double _appBarTextCap = mq.textScaleFactor > 1.0
        ? 1.0
        : mq.textScaleFactor;
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: showAppBar
          ? AppBar(
              elevation: 0,
              titleSpacing: 0,
              title: Row(
                children: [
                  Expanded(
                    child: isHome
                        ? GestureDetector(
                            onTap: onSearchTap,
                            child: Container(
                              margin: EdgeInsets.only(
                                left: AppDimens.spacingSm * _appBarIconScale,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    AppDimens.paddingLg * _appBarIconScale,
                                vertical:
                                    AppDimens.paddingSm * _appBarIconScale,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusFull,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: accentColor,
                                    size: AppDimens.iconSm * _appBarIconScale,
                                  ),
                                  SizedBox(
                                    width:
                                        AppDimens.spacingMd * _appBarIconScale,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'search_hint'.tr(),
                                      style: AppTextStyles.bodyMd(
                                        isDarkMode:
                                            Theme.of(context).brightness ==
                                            Brightness.dark,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.7),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            margin: EdgeInsets.only(
                              left: AppDimens.spacingSm * _appBarIconScale,
                            ),
                            child: Text(
                              titleKey.tr(),
                              style: AppTextStyles.titleLg(
                                isDarkMode:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.color,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                  if (Platform.isAndroid)
                    IconButton(
                      icon: Icon(
                        Icons.speaker_rounded,
                        size: AppDimens.iconLg * _appBarIconScale,
                      ),
                      onPressed: () => _showAudioOutputSheet(context),
                      tooltip: 'Audio Output',
                    ),
                ],
              ),
            )
          : null,
      body: child,
    );
  }
}
