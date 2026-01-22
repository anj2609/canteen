import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/auth_provider.dart';
import '../core/api_service.dart';
import 'main_screen.dart';
import 'owner/owner_main_view.dart';
import 'update_required_screen.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool? _isFirstRun;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('is_first_run') ?? true;

    if (mounted) {
      setState(() {
        _isFirstRun = isFirstRun;
      });

      if (!isFirstRun) {
        _startSplashAnimation();
      }
    }
  }

  void _startSplashAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => _navigateNext());
  }

  Future<void> _handleGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false);
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    try {
      // 1. Check App Version
      final api = ApiService();
      try {
        final versionData = await api.getAppVersion();

        if (versionData['success'] == true) {
          final minVersion = versionData['data']['minimumVersion'] as String;

          // Get current version
          final packageInfo = await PackageInfo.fromPlatform();
          final currentVersion = packageInfo.version;

          if (_isVersionLower(currentVersion, minVersion)) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => UpdateRequiredScreen(
                    currentVersion: currentVersion,
                    requiredVersion: minVersion,
                  ),
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Version check skipped: $e');
      }

      // Check Auth Status (Guest or User)
      await ref.read(authProvider.notifier).checkAuthStatus();
    } catch (e) {
      debugPrint('Navigate failed: $e');
    }

    if (mounted) {
      final authState = ref.read(authProvider);
      Widget nextScreen = const MainScreen();

      if (authState.isAuthenticated && authState.user?.role == 'admin') {
        nextScreen = const OwnerMainView();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  bool _isVersionLower(String current, String min) {
    List<int> cParts = current.split('.').map(int.parse).toList();
    List<int> mParts = min.split('.').map(int.parse).toList();

    // Pad dimensions
    while (cParts.length < 3) cParts.add(0);
    while (mParts.length < 3) mParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (cParts[i] < mParts[i]) return true;
      if (cParts[i] > mParts[i]) return false;
    }
    return false;
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRun == null) {
      return const Scaffold(backgroundColor: Colors.white);
    }

    if (_isFirstRun == true) {
      return _buildOnboardingUI();
    }

    return _buildSplashUI();
  }

  Widget _buildOnboardingUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'BunkBite',
              style: GoogleFonts.urbanist(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const Spacer(),
            // Central Image - Full Width
            SizedBox(
              width: double.infinity,
              child: SvgPicture.asset(
                'assets/images/iter1.svg',
                fit: BoxFit.cover,
              ),
            ),
            const Spacer(),
            // Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.urbanist(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: const Color(0xFF1A1A1A),
                      ),
                      children: [
                        const TextSpan(text: 'What are you\n'),
                        TextSpan(
                          text: 'craving today?',
                          style: TextStyle(color: Color(0xFF0B7D3B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quick order from your college canteen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get started',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplashUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/newlogo.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),
            FadeTransition(
              opacity: _opacityAnimation,
              child: Text(
                'Skip the queue.\nEat smart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
