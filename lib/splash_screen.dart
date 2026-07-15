import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bus_illustration.dart';
import 'onboarding_screen.dart';
import 'welcome_screen.dart';

/// Branded splash screen shown briefly when the app launches. Shows a
/// small convoy of illustrated buses (each labeled "NUTT" on its side)
/// driving in, followed by the app name and tagline.
///
/// After the splash duration, routes to OnboardingScreen the first time
/// the app is ever opened, and straight to WelcomeScreen on every launch
/// after that (tracked via SharedPreferences).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _busController;
  late final AnimationController _textController;

  late final Animation<Offset> _busSlideIn;
  late final Animation<double> _textFade;

  static const Color themeColor = Color(0xff10B981);
  static const Color darkThemeColor = Color(0xff0B7A5C);

  @override
  void initState() {
    super.initState();

    _busController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _busSlideIn = Tween<Offset>(
      begin: const Offset(-1.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _busController, curve: Curves.easeOutCubic));

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);

    _busController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    Timer(const Duration(milliseconds: 2600), _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            hasSeenOnboarding ? const WelcomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _busController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkThemeColor, themeColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Convoy of 3 buses, each slightly different size for depth.
              SlideTransition(
                position: _busSlideIn,
                child: SizedBox(
                  height: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      BusIllustration(
                        width: 78,
                        height: 46,
                        busColor: Colors.white70,
                        accentColor: Colors.white,
                      ),
                      SizedBox(width: 10),
                      BusIllustration(
                        width: 110,
                        height: 64,
                        busColor: Colors.white,
                        accentColor: darkThemeColor,
                      ),
                      SizedBox(width: 10),
                      BusIllustration(
                        width: 78,
                        height: 46,
                        busColor: Colors.white70,
                        accentColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Ground/road line under the buses.
              Container(
                width: 220,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 36),

              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const Text(
                      "NUTT TRAVEL",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Gujrat's Trusted Bus Service",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 44),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
