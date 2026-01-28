import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            _ProfileHeader(
              name: user?.name ?? 'Guest',
              email: user?.email ?? '',
              avatarUrl: user?.avatarUrl,
              onEditProfile: () => context.push('/edit-profile'),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Stats
            if (user != null)
              _StatsSection(
                postsCount: 5, // Would come from user data
                reunionsCount: 2,
                matchesCount: 8,
              ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Menu items
            _MenuSection(
              title: 'My Activity',
              items: [
                _MenuItem(
                  icon: Icons.article_outlined,
                  title: 'My Posts',
                  subtitle: 'View and manage your posts',
                  onTap: () => context.push('/my-posts'),
                ),
                _MenuItem(
                  icon: Icons.bookmark_outline,
                  title: 'Saved Items',
                  subtitle: 'Items you bookmarked',
                  onTap: () => context.push('/bookmarks'),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Alert Preferences',
                  subtitle: 'Customize your notifications',
                  onTap: () => context.push('/settings/notifications'),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            _MenuSection(
              title: 'Preferences',
              items: [
                _ThemeMenuItem(
                  currentTheme: ref.watch(themeProvider),
                  onThemeChanged: (mode) {
                    ref.read(themeProvider.notifier).setTheme(mode);
                  },
                ),
                _MenuItem(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {
                    // TODO: Language selection
                  },
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Default Location',
                  subtitle: 'Set your area for relevant posts',
                  onTap: () {
                    // TODO: Location settings
                  },
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            _MenuSection(
              title: 'About',
              items: [
                _MenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.info_outline,
                  title: 'About LostLink',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Logout button
            if (user != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(context, ref),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

            if (user == null)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create Account'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'G',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onEditProfile,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Name
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        // Email
        if (email.isNotEmpty)
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int postsCount;
  final int reunionsCount;
  final int matchesCount;

  const _StatsSection({
    required this.postsCount,
    required this.reunionsCount,
    required this.matchesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: postsCount.toString(), label: 'Posts'),
          _StatDivider(),
          _StatItem(value: reunionsCount.toString(), label: 'Reunited'),
          _StatDivider(),
          _StatItem(value: matchesCount.toString(), label: 'Matches'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: AppColors.dividerLight,
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right),
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  final ThemeMode currentTheme;
  final Function(ThemeMode) onThemeChanged;

  const _ThemeMenuItem({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _showThemeDialog(context),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          currentTheme == ThemeMode.dark
              ? Icons.dark_mode
              : currentTheme == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
          color: AppColors.primary,
        ),
      ),
      title: const Text('Theme'),
      subtitle: Text(
        _getThemeName(currentTheme),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
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
            _ThemeOption(
              icon: Icons.light_mode,
              title: 'Light',
              isSelected: currentTheme == ThemeMode.light,
              onTap: () {
                onThemeChanged(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark',
              isSelected: currentTheme == ThemeMode.dark,
              onTap: () {
                onThemeChanged(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              icon: Icons.brightness_auto,
              title: 'System',
              isSelected: currentTheme == ThemeMode.system,
              onTap: () {
                onThemeChanged(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
    );
  }
}
