import 'package:flutter/material.dart';
import '../../data/models/app_info_model.dart';
import '../../data/repositories/app_info_repository.dart';
import '../legal_screen.dart';

const Color kGreen = Color(0xFF0C831F);

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('About us')),
      body: FutureBuilder<AppInfoModel>(
        future: AppInfoRepository().fetchAppInfo(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load info. Please try again later.'));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: kGreen));
          }
          final info = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.bolt, size: 56, color: kGreen),
                    const SizedBox(height: 8),
                    Text(info.appName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Version ${info.version} (${info.buildNumber})',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _tile(context, Icons.business_outlined, 'Company', info.company,
                  onTap: () {}),
              _tile(context, Icons.description_outlined, 'Terms of service',
                  null, onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const LegalScreen(type: LegalDocType.terms)));
              }),
              _tile(context, Icons.privacy_tip_outlined, 'Privacy policy',
                  null, onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const LegalScreen(type: LegalDocType.privacy)));
              }),
              _tile(context, Icons.article_outlined, 'Open source licenses',
                  null, onTap: () => showLicensePage(context: context)),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      String? subtitle,
      {required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: kGreen),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
