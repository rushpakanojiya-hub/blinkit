import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kGreen = Color(0xFF0C831F);

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: kGreen));
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyView({super.key, required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: scheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(message, style: GoogleFonts.poppins(fontSize: 14, color: scheme.onSurface.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: kGreen),
            child: Text('Retry', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
