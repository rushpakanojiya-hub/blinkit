import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'otp_screen.dart';
import 'home_screen.dart';

const Color kBrandGreen = Color(0xFF0C831F);
const Color kBrandGreenDark = Color(0xFF08611A);
const Color kBrandGreenLight = Color(0xFF12A32E);
const Color kHeroBg = Color(0xFF017731);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool get _isValid => _phoneController.text.length == 10;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isSending = false;

  void _continue() async {
    if (!_isValid || _isSending) return;
    setState(() => _isSending = true);
    try {
      final data = await ApiService.sendOTP(_phoneController.text);
      debugPrint('SEND OTP RESPONSE: $data');
      setState(() => _isSending = false);
      if (data['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'].toString())),
          );
        }
        return;
      }
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              phone: _phoneController.text,
              // TEST MODE ONLY: backend currently returns the OTP directly
              // in the send-otp response (no real SMS). Remove this once a
              // real SMS provider is wired back up.
              testOtp: data['otp']?.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending OTP: $e')),
        );
      }
    }
  }

  void _skipLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget _buildMobile(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerHeight = screenHeight * 0.45;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBanner(height: bannerHeight, onSkip: _skipLogin),
              Container(
                height: 70,
                color: kHeroBg,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.two_wheeler, color: kBrandGreen, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Fresh. Fast. Reliable.',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _LoginBottomSheet(
                phoneController: _phoneController,
                isValid: _isValid,
                onContinue: _continue,
                onChanged: () => setState(() {}),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return _buildWeb(context);
    }
    return _buildMobile(context);
  }

  Widget _buildWeb(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [kHeroBg, kBrandGreenDark],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt, color: kBrandGreen, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'GoFresh',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Groceries delivered\nin minutes.',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Fresh produce, daily essentials and more, delivered to your door,\nfast and reliable.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      _webStat('10 min', 'Delivery'),
                      const SizedBox(width: 40),
                      _webStat('24/7', 'Support'),
                      const SizedBox(width: 40),
                      _webStat('100%', 'Fresh'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: GoogleFonts.poppins(
                        color: kBrandGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log In or Sign Up',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your mobile number to continue to GoFresh.',
                      style: GoogleFonts.poppins(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Mobile Number',
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('+91', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: 'Enter mobile number',
                                contentPadding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              style: GoogleFonts.poppins(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isValid && !_isSending ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandGreen,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Send OTP',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Protected access - GoFresh',
                        style: GoogleFonts.poppins(color: Colors.black38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final double height;
  final VoidCallback onSkip;

  const _HeroBanner({required this.height, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kHeroBg,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipPath(
          clipper: _BannerCurveClipper(),
          child: Container(
            color: kHeroBg,
            child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  height: height,
                  child: Image.asset(
                    'assets/images/auth/login_hero.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: SafeArea(
                  bottom: false,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Skip login',
                        style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _BannerCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 36);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 36);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LoginBottomSheet extends StatelessWidget {
  final TextEditingController phoneController;
  final bool isValid;
  final VoidCallback onContinue;
  final VoidCallback onChanged;

  const _LoginBottomSheet({
    required this.phoneController,
    required this.isValid,
    required this.onContinue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kBrandGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: 'Go', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                  TextSpan(text: 'Fresh', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: kBrandGreen)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "India's fastest app",
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Log In or Sign Up',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 15,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFF9933), Colors.white, Color(0xFF138808)],
                              stops: [0.33, 0.5, 0.66],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('+91', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Enter mobile number',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      style: GoogleFonts.poppins(fontSize: 15),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? kBrandGreen : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                text: 'By continuing, you agree to our ',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                children: [
                  TextSpan(text: 'Terms of service', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87, decoration: TextDecoration.underline)),
                  const TextSpan(text: ' & '),
                  TextSpan(text: 'Privacy policy', style: GoogleFonts.poppins(fontSize: 11, color: Colors.black87, decoration: TextDecoration.underline)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

