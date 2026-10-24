import '../features/wishlist/presentation/providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../services/push_notification_service.dart';

const Color kBrandGreen = Color(0xFF0C831F);

class OtpScreen extends StatefulWidget {
  final String phone;
  // TEST MODE ONLY: OTP returned directly by the backend (no real SMS).
  // Remove once a real SMS provider is wired back up.
  final String? testOtp;
  const OtpScreen({super.key, required this.phone, this.testOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 30;
  bool _isVerifying = false;
  bool _showSmsBanner = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.testOtp == null)
        setState(() => _showSmsBanner = false);
    });
    // TEST MODE ONLY: auto-fill and auto-verify using the OTP the backend
    // returned directly (no real SMS). Remove once a real SMS provider is
    // wired back up.
    if (widget.testOtp != null && widget.testOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (var i = 0; i < 6; i++) {
          _controllers[i].text = widget.testOtp![i];
        }
        if (mounted) setState(() {});
        _verify();
      });
    }
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  // MOCK: any 4 digits logs the user in. Replace with real API call later.
  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _isVerifying = true);
    try {
      final data = await ApiService.verifyOTP(widget.phone, _otp);
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final prevPhone = prefs.getString('user_phone');
        if (prevPhone != widget.phone && mounted) {
          context.read<WishlistProvider>().clear();
        }
        await prefs.setString('user_phone', widget.phone);
        PushNotificationService.initialize();
        PushNotificationService.registerCurrentToken();
        if (mounted) {
          context.read<SettingsProvider>().load();
          await context.read<CartProvider>().syncLocalCartToServer();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(showWishlistIntro: true),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() => _isVerifying = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error']?.toString() ?? 'OTP verify fail hua'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otp.length == 6) {
      FocusScope.of(context).unfocus();
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OTP verification',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text.rich(
                  TextSpan(
                    text: "We've sent a verification code to\n",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    children: [
                      TextSpan(
                        text: '+91 ${widget.phone}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 46,
                        height: 56,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFFF2F4F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: kBrandGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                _secondsLeft > 0
                    ? Text(
                        'Resend OTP in $_secondsLeft',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      )
                    : TextButton(
                        onPressed: _startTimer,
                        child: Text(
                          'Resend OTP',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kBrandGreen,
                          ),
                        ),
                      ),
                if (_isVerifying) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: kBrandGreen,
                    strokeWidth: 2,
                  ),
                ],
              ],
            ),
          ),
          if (widget.testOtp != null)
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'TEST MODE -- OTP: ${widget.testOtp} (auto-filled)',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else if (_showSmsBanner)
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'We have sent a verification code to you via SMS',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
