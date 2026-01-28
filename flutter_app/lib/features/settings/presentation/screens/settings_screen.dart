import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Notifications section
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Get notified about matches and messages',
                value: true,
                onChanged: (value) {
                  // TODO: Toggle push notifications
                },
              ),
              _SwitchTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Receive updates via email',
                value: false,
                onChanged: (value) {
                  // TODO: Toggle email notifications
                },
              ),
              _SwitchTile(
                icon: Icons.link_outlined,
                title: 'Match Alerts',
                subtitle: 'Get instant alerts when AI finds a match',
                value: true,
                onChanged: (value) {
                  // TODO: Toggle match alerts
                },
              ),
            ],
          ),

          // Appearance section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _ThemeTile(
                currentTheme: ref.watch(themeModeProvider),
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                },
              ),
            ],
          ),

          // Privacy section
          _SettingsSection(
            title: 'Privacy',
            children: [
              _SwitchTile(
                icon: Icons.visibility_outlined,
                title: 'Show Profile',
                subtitle: 'Allow others to view your profile',
                value: true,
                onChanged: (value) {
                  // TODO: Toggle profile visibility
                },
              ),
              _SwitchTile(
                icon: Icons.phone_outlined,
                title: 'Show Phone Number',
                subtitle: 'Display phone on your posts',
                value: false,
                onChanged: (value) {
                  // TODO: Toggle phone visibility
                },
              ),
              _NavigationTile(
                icon: Icons.block_outlined,
                title: 'Blocked Users',
                onTap: () {
                  // TODO: Navigate to blocked users
                },
              ),
            ],
          ),

          // Data section
          _SettingsSection(
            title: 'Data & Storage',
            children: [
              _NavigationTile(
                icon: Icons.download_outlined,
                title: 'Download My Data',
                onTap: () {
                  // TODO: Download data
                },
              ),
              _NavigationTile(
                icon: Icons.delete_sweep_outlined,
                title: 'Clear Cache',
                subtitle: '12.5 MB',
                onTap: () {
                  _showClearCacheDialog(context);
                },
              ),
            ],
          ),

          // About section
          _SettingsSection(
            title: 'About',
            children: [
              _NavigationTile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: '1.0.0 (Build 1)',
                onTap: () {},
              ),
              _NavigationTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // TODO: Open terms
                },
              ),
              _NavigationTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
              _NavigationTile(
                icon: Icons.code_outlined,
                title: 'Open Source Licenses',
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'LostLink',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will clear cached images and data. Your posts and settings will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        currentTheme == ThemeMode.dark
            ? Icons.dark_mode
            : currentTheme == ThemeMode.light
                ? Icons.light_mode
                : Icons.brightness_auto,
        color: AppColors.primary,
      ),
      title: const Text('Theme'),
      subtitle: Text(_getThemeName(currentTheme)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              secondary: const Icon(Icons.light_mode),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) onChanged(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              secondary: const Icon(Icons.dark_mode),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) onChanged(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              secondary: const Icon(Icons.brightness_auto),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) onChanged(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
