import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../services/push_notification_service.dart';

const Color kSplashBg = Color(0xFF0A0F0A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      // Re-check mounted AFTER the await -- the widget may have been
      // disposed while we were waiting on SharedPreferences.
      if (!mounted) return;
      final token = prefs.getString('token');
      final skipped = prefs.getBool('skipped_login') ?? false;
      if (token != null && token.isNotEmpty) {
        PushNotificationService.initialize();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => (skipped || (token != null && token.isNotEmpty))
              ? const HomeScreen()
              : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSplashBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash/splash_hero.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
