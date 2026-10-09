import 'package:flutter/material.dart';
import '../../../onboarding/presentation/screens/intro_screen.dart';
import '../../../main_screen/router/display_route.dart';
import '../../../../core/services/settings_storage_service.dart';

class AuralisColors {
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color secondaryPink = Color(0xFFFF63B8);
  static const Color backgroundColor = Color(0xFF1A1A1A);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final box = await SettingsStorageService.getBox();
    final bool isFirstTime = (box.get('first_time') as bool?) ?? true;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isFirstTime ? const IntroScreen() : const MainScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AuralisColors.backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: _getResponsiveLogoSize(size),
                                height: _getResponsiveLogoSize(size),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: LinearGradient(
                                    colors: [
                                      AuralisColors.primaryPurple,
                                      AuralisColors.secondaryPink,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AuralisColors.primaryPurple
                                          .withValues(
                                            alpha:
                                                0.35 * _opacityAnimation.value,
                                          ),
                                      blurRadius: 30.0,
                                      spreadRadius: 6.0,
                                    ),
                                    BoxShadow(
                                      color: AuralisColors.secondaryPink
                                          .withValues(
                                            alpha:
                                                0.25 * _opacityAnimation.value,
                                          ),
                                      blurRadius: 60.0,
                                      spreadRadius: 14.0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Image.asset(
                                    'assets/default_artwork.png',
                                    width: _getResponsiveLogoSize(size),
                                    height: _getResponsiveLogoSize(size),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: _getResponsiveSpacing(size)),
                              Text(
                                'Auralis',
                                style: TextStyle(
                                  fontSize: _getResponsiveFontSize(size),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  double _getResponsiveLogoSize(Size size) {
    const double mobileBreakpoint = 600;
    const double tabletBreakpoint = 1200;

    double logoSize;

    if (size.width < mobileBreakpoint) {
      logoSize = size.width * 0.35; // 35% of screen width for mobile
      logoSize = logoSize.clamp(120.0, 200.0); // Min 120, Max 200
    } else if (size.width < tabletBreakpoint) {
      logoSize = size.width * 0.25; // 25% of screen width for tablet
      logoSize = logoSize.clamp(180.0, 280.0); // Min 180, Max 280
    } else {
      logoSize = size.width * 0.18; // 18% of screen width for desktop
      logoSize = logoSize.clamp(250.0, 350.0); // Min 250, Max 350
    }

    return logoSize;
  }

  double _getResponsiveFontSize(Size size) {
    const double mobileBreakpoint = 600;
    const double tabletBreakpoint = 1200;

    double fontSize;

    if (size.width < mobileBreakpoint) {
      fontSize = size.width * 0.07;
      fontSize = fontSize.clamp(24.0, 36.0);
    } else if (size.width < tabletBreakpoint) {
      fontSize = size.width * 0.06;
      fontSize = fontSize.clamp(32.0, 48.0);
    } else {
      fontSize = size.width * 0.045;
      fontSize = fontSize.clamp(40.0, 60.0);
    }

    return fontSize;
  }

  double _getResponsiveSpacing(Size size) {
    const double mobileBreakpoint = 600;
    const double tabletBreakpoint = 1200;

    double spacing;

    if (size.width < mobileBreakpoint) {
      spacing = size.height * 0.025;
      spacing = spacing.clamp(16.0, 24.0);
    } else if (size.width < tabletBreakpoint) {
      spacing = size.height * 0.03;
      spacing = spacing.clamp(20.0, 32.0);
    } else {
      spacing = size.height * 0.035;
      spacing = spacing.clamp(28.0, 40.0);
    }

    return spacing;
  }
}
