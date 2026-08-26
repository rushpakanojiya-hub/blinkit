import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/support_provider.dart';
import '../../widgets/state_views.dart';

const Color kGreen = Color(0xFF0C831F);

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({super.key});
  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadFaqs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onSurface),
        title: Text('Need Help', style: GoogleFonts.poppins(color: scheme.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _optionTile(scheme, Icons.chat_bubble_outline, 'Chat Support', () async {
            final uri = Uri.parse(
                'https://wa.me/918104090442?text=${Uri.encodeComponent('Hi, I am facing an issue with a product I ordered. ')}');
            if (await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open WhatsApp')),
              );
            }
          }),
          _optionTile(scheme, Icons.call_outlined, 'Call Support', () async {
            final uri = Uri(scheme: 'tel', path: '18001234567');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          }),
          _optionTile(scheme, Icons.email_outlined, 'Email Support', () async {
            final uri = Uri(scheme: 'mailto', path: 'support@gofresh.app', query: 'subject=Help needed');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          }),
          const SizedBox(height: 20),
          Text('Frequently Asked Questions',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
          const SizedBox(height: 12),
          Consumer<SupportProvider>(
            builder: (context, provider, _) {
              if (provider.faqStatus == LoadStatus.loading) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: LoadingView());
              }
              if (provider.faqStatus == LoadStatus.error) {
                return ErrorView(
                  message: provider.faqError ?? 'Could not load FAQs',
                  onRetry: () => provider.loadFaqs(),
                );
              }
              if (provider.faqs.isEmpty) {
                return const EmptyView(icon: Icons.help_outline, message: 'No FAQs available');
              }
              return Column(
                children: provider.faqs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final faq = entry.value;
                  final isOpen = _expanded.contains(i);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration:
                        BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => isOpen ? _expanded.remove(i) : _expanded.add(i)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(faq.question,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                                ),
                                Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: scheme.onSurface.withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(faq.answer,
                                  style:
                                      GoogleFonts.poppins(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.7))),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _optionTile(ColorScheme scheme, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: kGreen),
        title: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.4)),
        onTap: onTap,
      ),
    );
  }
}
