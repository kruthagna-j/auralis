import 'dart:io';

import 'package:flutter/material.dart';
import 'package:terminate_restart/terminate_restart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../main_screen/router/display_route.dart';
import 'theme_setup_screen.dart';
import 'package:provider/provider.dart';
import 'artist_setup_screen.dart';
import '../../../settings/presentation/screens/language_selection_screen.dart';
// import '../../../main_screen/router/display_route.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/settings_storage_service.dart';
import '../../../../shared/components/app_snackbar.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  final List<IntroPage> _pages = [
    const IntroPage(
      title: 'Welcome to Auralis',
      subtitle: 'AI-Powered Music Companion',
      svgAsset: 'assets/images/intro_ai_music.svg',
      iconColor: Color(0xFF6366F1),
    ),
    const IntroPage(
      title: 'Discover & Explore',
      subtitle: 'Find Your Perfect Sound',
      svgAsset: 'assets/images/intro_discover.svg',
      iconColor: Color(0xFF10B981),
    ),
    const IntroPage(
      title: 'Download & Listen',
      subtitle: 'Music Anywhere, Anytime',
      svgAsset: 'assets/images/intro_download.svg',
      iconColor: Color(0xFFf59E0B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _pageController = PageController();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDimens.animSmooth,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    _slideController = AnimationController(
      vsync: this,
      duration: AppDimens.animSmooth,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildMobileContent(IntroPage page, BoxConstraints constraints) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;
    final imageSize = (h * 0.38).clamp(100.0, w * 0.65);
    final gap1 = (h * 0.04).clamp(8.0, 32.0);
    final gap2 = (h * 0.015).clamp(4.0, 12.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: SvgPicture.asset(page.svgAsset, fit: BoxFit.contain),
        ),
        SizedBox(height: gap1),
        Text(
          page.title,
          style: AppTextStyles.display(
            isDarkMode: false,
            color: const Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: gap2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingXl),
          child: Text(
            page.subtitle,
            style: AppTextStyles.subtitle(
              isDarkMode: false,
              color: page.iconColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(Size size) {
    final page = _pages[_currentPage];
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedContainer(
            duration: AppDimens.animSmooth,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.iconColor.withValues(alpha: 0.30),
                  page.iconColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _slideController.forward(from: 0);
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.spacing5Xl),
                      child: SvgPicture.asset(
                        _pages[index].svgAsset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 48.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _startSetup,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.subtitle(
                        isDarkMode: false,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: page.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXs * 4),
                  ),
                  child: Text(
                    '${_currentPage + 1} of ${_pages.length}',
                    style: AppTextStyles.subtitle(
                      isDarkMode: false,
                      color: page.iconColor,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  page.title,
                  style: AppTextStyles.hero(
                    isDarkMode: false,
                    color: const Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  page.subtitle,
                  style: AppTextStyles.display(
                    isDarkMode: false,
                    color: page.iconColor,
                  ),
                ),

                const Spacer(),

                Row(
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: AppDimens.animDefault,
                      margin: const EdgeInsets.only(right: AppDimens.spacingXs),
                      height: AppDimens.spacingSm,
                      width: _currentPage == index
                          ? AppDimens.spacingXxl
                          : AppDimens.spacingSm,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? page.iconColor
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    if (_currentPage > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: page.iconColor,
                              width: AppDimens.dividerHeight,
                            ),
                            minimumSize: const Size(
                              double.infinity,
                              AppDimens.buttonSizeDefault,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            'Previous',
                            style: AppTextStyles.subtitle(
                              isDarkMode: false,
                              color: page.iconColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: page.iconColor,
                          minimumSize: const Size(
                            double.infinity,
                            AppDimens.buttonSizeDefault,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusLg,
                            ),
                          ),
                          elevation: AppDimens.elevationNone,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: AppTextStyles.subtitle(
                            isDarkMode: false,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppDimens.animSmooth,
        curve: Curves.easeInOut,
      );
    } else {
      _startSetup();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDimens.animSmooth,
        curve: Curves.easeInOut,
      );
    }
  }

  void _startSetup() async {
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.hasInternet) {
      AppSnackBar.showError(
        context,
        'No internet connection. Please connect to the internet to continue setup.',
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: LanguageSelectionScreen(
            isOnboardingFlow: true,
            onSelected: () {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      FadeTransition(
                        opacity: animation,
                        child: ThemeSetupScreen(
                          onNext: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        FadeTransition(
                                          opacity: animation,
                                          child: ArtistSetupScreen(
                                            onComplete: _completeSetup,
                                          ),
                                        ),
                              ),
                            );
                          },
                        ),
                      ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _completeSetup() async {
    final box = await SettingsStorageService.getBox();
    await box.put('first_time', false);

    if (mounted) {
      // Navigator.pushReplacement(
      //   context,
      //   PageRouteBuilder(
      //     pageBuilder: (context, animation, secondaryAnimation) =>
      //         FadeTransition(opacity: animation, child: const MainScreen()),
      //   ),
      // );
      if (Platform.isAndroid)
        await TerminateRestart.instance.restartApp(
          options: const TerminateRestartOptions(terminate: true),
        );
      else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                FadeTransition(opacity: animation, child: const MainScreen()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 720;

            if (isDesktop) {
              return _buildDesktopLayout(size);
            }

            final page = _pages[_currentPage];
            final backgroundGradient = LinearGradient(
              colors: [
                page.iconColor.withValues(alpha: 0.18),
                page.iconColor.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

            return AnimatedContainer(
              width: double.infinity,
              height: double.infinity,
              duration: AppDimens.animSmooth,
              curve: Curves.easeInOut,
              decoration: BoxDecoration(gradient: backgroundGradient),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextButton(
                        onPressed: _startSetup,
                        child: Text(
                          'Skip',
                          style: AppTextStyles.subtitle(
                            isDarkMode: false,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _slideController.forward(from: 0);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: LayoutBuilder(
                            builder: (context, innerConstraints) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingXl,
                              ),
                              child: _buildMobileContent(
                                _pages[index],
                                innerConstraints,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (size.width * 0.06).clamp(16.0, 48.0),
                      vertical: (size.height * 0.03).clamp(12.0, 28.0),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (index) {
                            return AnimatedContainer(
                              duration: AppDimens.animDefault,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppDimens.spacingXs,
                              ),
                              height: AppDimens.spacingSm,
                              width: _currentPage == index
                                  ? AppDimens.spacingXxl
                                  : AppDimens.spacingSm,
                              decoration: BoxDecoration(
                                color: _currentPage == index
                                    ? page.iconColor
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusXs,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: AppDimens.spacingXxl),
                        Row(
                          children: [
                            if (_currentPage > 0) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _previousPage,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: page.iconColor,
                                      width: AppDimens.dividerHeight,
                                    ),
                                    minimumSize: Size(
                                      double.infinity,
                                      AppDimens.buttonSizeDefault,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppDimens.radiusLg,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Previous',
                                    style: AppTextStyles.subtitle(
                                      isDarkMode: false,
                                      color: page.iconColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: page.iconColor,
                                  minimumSize: Size(
                                    double.infinity,
                                    AppDimens.buttonSizeDefault,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDimens.radiusLg,
                                    ),
                                  ),
                                  elevation: AppDimens.elevationNone,
                                ),
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: AppTextStyles.subtitle(
                                    isDarkMode: false,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class IntroPage {
  final String title;
  final String subtitle;
  final String svgAsset;
  final Color iconColor;

  const IntroPage({
    required this.title,
    required this.subtitle,
    required this.svgAsset,
    required this.iconColor,
  });
}
