import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _goToLogin();
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C831F),
      body: Stack(
        children: [
          // Full-screen background image with the whole onboarding design
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding/onboarding_hero.png',
              fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),

          // Skip button
          Positioned(
            top: 50,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tap area over the "Get Started" button drawn in the image
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            height: 70,
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _goToLogin,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
