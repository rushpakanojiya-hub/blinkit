import 'package:flutter/material.dart';

const Color kGreen = Color(0xFF0C831F);

class _PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  bool granted;

  _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
  });
}

class AppPermissionsScreen extends StatefulWidget {
  const AppPermissionsScreen({super.key});

  @override
  State<AppPermissionsScreen> createState() => _AppPermissionsScreenState();
}

class _AppPermissionsScreenState extends State<AppPermissionsScreen> {
  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      icon: Icons.location_on_outlined,
      title: 'Location',
      description:
          'Used to detect your delivery address and show nearby stores with accurate delivery times.',
      granted: true,
    ),
    _PermissionItem(
      icon: Icons.camera_alt_outlined,
      title: 'Camera',
      description:
          'Used to scan QR codes for payments and to upload a profile photo.',
      granted: false,
    ),
    _PermissionItem(
      icon: Icons.notifications_none_outlined,
      title: 'Notifications',
      description:
          'Used to send order updates, delivery alerts, offers and wallet activity.',
      granted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(title: const Text('App permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Manage what GoFresh can access on your device. You can change these anytime from your phone settings as well.',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                for (int i = 0; i < _permissions.length; i++) ...[
                  _buildPermissionTile(_permissions[i]),
                  if (i != _permissions.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(_PermissionItem item) {
    return SwitchListTile(
      value: item.granted,
      activeThumbColor: kGreen,
      secondary: Icon(item.icon, color: kGreen),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(item.description),
      onChanged: (value) {
        setState(() => item.granted = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${item.title} ${value ? 'enabled' : 'disabled'}'),
            backgroundColor: kGreen,
          ),
        );
      },
    );
  }
}