import 'package:flutter/material.dart';

/// Matches the rounded white-card style already used on the Profile screen.
class SettingsSectionCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }
}
