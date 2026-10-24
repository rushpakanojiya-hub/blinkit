import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBrandGreen = Color(0xFF0C831F);

Future<void> showWishlistIntro(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const WishlistIntroSheet(),
  );
}

class WishlistIntroSheet extends StatelessWidget {
  const WishlistIntroSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _card('assets/images/wishlist_intro/card1.png'),
              const SizedBox(width: 12),
              _card(
                'assets/images/wishlist_intro/card2.png',
                highlighted: true,
              ),
              const SizedBox(width: 12),
              _card('assets/images/wishlist_intro/card3.png'),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'INTRODUCING',
            style: GoogleFonts.poppins(
              fontSize: 12,
              letterSpacing: 1.2,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Wishlist',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save your favourites and find them fast when you shop next',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it, Thanks!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String imagePath, {bool highlighted = false}) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFCE4E4) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      alignment: Alignment.topRight,
      padding: const EdgeInsets.all(8),
      child: Icon(
        Icons.favorite,
        color: highlighted ? Colors.red : Colors.grey.shade300,
        size: 20,
      ),
    );
  }
}
