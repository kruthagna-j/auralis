import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';

import 'package:provider/provider.dart';

import '../../../favorite_artist/presentation/screens/favorite_artist_screen.dart';
import '../widgets/audio_output_bottomsheet.dart';

import '../../../downloads/presentation/screens/downloads_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../player/presentation/screens/player_ui.dart';
import '../../../library/presentation/screens/library_screen.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../stats/presentation/screens/stats_screen.dart';
import '../../../trending/presentation/screens/trending_screen.dart';
import 'full_player_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _innerNavKey = GlobalKey<NavigatorState>();

  bool _isExpanded = true;

  late TextStyle _titleStyle;
  late TextStyle _selectedLabelStyle;
  late TextStyle _unselectedLabelStyle;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const TrendingScreen(),
    const PlaylistScreen(),
    const LibraryScreen(),
    const FavoriteArtistsScreen(),
    const SettingsScreen(),
    const DownloadsScreen(),
    StatsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStyles();
  }

  Future<void> _showAudioOutputSheet() async {
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

  void _updateStyles() {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;

    _titleStyle = AppTextStyles.headingLg(isDarkMode: isDarkMode);

    _selectedLabelStyle = AppTextStyles.caption(isDarkMode: isDarkMode)
        .copyWith(
          fontWeight: FontWeight.w600,
          color: settingsProvider.accentColor,
        );

    _unselectedLabelStyle = AppTextStyles.finePrint(isDarkMode: isDarkMode)
        .copyWith(
          color: MainScreenColors.getTextColor(
            isDarkMode,
          ).withValues(alpha: 0.5),
        );
  }

  // --- Custom Navigation Item Builder ---
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required SettingsProvider settingsProvider,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_innerNavKey.currentState?.canPop() ?? false) {
              _innerNavKey.currentState!.popUntil((route) => route.isFirst);
            }
            setState(() => _currentIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? settingsProvider.accentColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : MainScreenColors.getTextColor(
                          isDarkMode,
                        ).withValues(alpha: 0.6),
                  size: isSelected ? AppDimens.iconXl : AppDimens.iconLg,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: _selectedLabelStyle.copyWith(
                        color: isSelected
                            ? Colors.white
                            : MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.6),
                        fontSize: AppTextStyles.fontSizeCaption,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final playerProvider = Provider.of<PlayerProvider>(context);
    final hasPlayer =
        playerProvider.currentSong != null ||
        playerProvider.lastPlayedSong != null;

    return WillPopScope(
      onWillPop: () async {
        if (_innerNavKey.currentState != null &&
            _innerNavKey.currentState!.canPop()) {
          _innerNavKey.currentState!.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: MainScreenColors.getBackgroundColor(isDarkMode),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: _isExpanded ? 240 : 84,
                    decoration: BoxDecoration(
                      color: MainScreenColors.getSurfaceColor(
                        isDarkMode,
                      ).withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: AppDimens.elevationHigh,
                          offset: const Offset(AppDimens.spacingXxs, 0),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isExpanded ? Icons.menu_open : Icons.menu,
                                ),
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                tooltip: _isExpanded
                                    ? 'Collapse Menu'
                                    : 'Expand Menu',
                              ),
                              const SizedBox(height: AppDimens.spacingS),
                              IconButton(
                                icon: Icon(
                                  isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ),
                                ),
                                onPressed: () => settingsProvider.toggleTheme(),
                                tooltip: 'Toggle Theme',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _buildNavItem(
                                index: 0,
                                icon: Icons.home,
                                label: 'home'.tr(),
                                isSelected: _currentIndex == 0,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 1,
                                icon: Icons.search,
                                label: 'search'.tr(),
                                isSelected: _currentIndex == 1,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 2,
                                icon: Icons.trending_up,
                                label: 'trending'.tr(),
                                isSelected: _currentIndex == 2,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 3,
                                icon: Icons.playlist_play,
                                label: 'playlists'.tr(),
                                isSelected: _currentIndex == 3,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 4,
                                icon: Icons.library_music_outlined,
                                label: 'library'.tr(),
                                isSelected: _currentIndex == 4,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 5,
                                icon: Icons.person_outline,
                                label: 'artists'.tr(),
                                isSelected: _currentIndex == 5,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 6,
                                icon: Icons.settings,
                                label: 'settings'.tr(),
                                isSelected: _currentIndex == 6,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 7,
                                icon: Icons.download_done_sharp,
                                label: 'downloads'.tr(),
                                isSelected: _currentIndex == 7,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                              _buildNavItem(
                                index: 8,
                                icon: Icons.show_chart,
                                label: 'stats'.tr(),
                                isSelected: _currentIndex == 8,
                                settingsProvider: settingsProvider,
                                isDarkMode: isDarkMode,
                              ),
                            ],
                          ),
                        ),
                        if (Platform.isAndroid)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: IconButton(
                              icon: Icon(
                                Icons.speaker_rounded,
                                color: MainScreenColors.getTextColor(
                                  isDarkMode,
                                ),
                              ),
                              onPressed: _showAudioOutputSheet,
                              tooltip: 'Audio Output',
                            ),
                          ),
                      ],
                    ),
                  ),
                  // --- Main Content Area ---
                  Expanded(
                    child: Navigator(
                      key: _innerNavKey,
                      onGenerateRoute: (RouteSettings settings) {
                        return MaterialPageRoute(
                          settings: settings,
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(AppDimens.paddingLg),
                            child: IndexedStack(
                              index: _currentIndex,
                              children: _screens,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (hasPlayer)
              SizedBox(
                height: AppDimens.miniPlayerHeightWide,
                child: PlayerUI(
                  showFullScreen: false,
                  isEmbedded: true,
                  onMinimize: () {},
                  onExpand: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            _DesktopFullPlayerResponsiveWrapper(
                              child: const FullPlayerScreen(),
                              onSwitchToMobile: (wrapperContext) {
                                if (Navigator.of(wrapperContext).canPop()) {
                                  Navigator.of(wrapperContext).pop();
                                }
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (MediaQuery.of(wrapperContext).size.width <
                                      AppDimens.breakpointMobile) {
                                    showModalBottomSheet(
                                      context: wrapperContext,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      enableDrag: true,
                                      builder: (context) => SafeArea(
                                        child: SizedBox(
                                          height: MediaQuery.of(
                                            context,
                                          ).size.height,
                                          child: const FullPlayerScreen(),
                                        ),
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DesktopFullPlayerResponsiveWrapper extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext wrapperContext) onSwitchToMobile;

  const _DesktopFullPlayerResponsiveWrapper({
    Key? key,
    required this.child,
    required this.onSwitchToMobile,
  }) : super(key: key);

  @override
  State<_DesktopFullPlayerResponsiveWrapper> createState() =>
      _DesktopFullPlayerResponsiveWrapperState();
}

class _DesktopFullPlayerResponsiveWrapperState
    extends State<_DesktopFullPlayerResponsiveWrapper>
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
    if (!_hasSwitched && width < AppDimens.breakpointMobile) {
      _hasSwitched = true;
      widget.onSwitchToMobile(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
