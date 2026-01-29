import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull?.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: GradientText(
                text: 'Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                gradient: AppColors.secondaryGradient,
              ),
              actions: [
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: isDark ? Colors.white70 : AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.heroGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
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
                  postsCount: 5,
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
                    gradient: AppColors.primaryGradient,
                  ),
                  _MenuItem(
                    icon: Icons.bookmark_outline,
                    title: 'Saved Items',
                    subtitle: 'Items you bookmarked',
                    onTap: () => context.push('/bookmarks'),
                    gradient: AppColors.secondaryGradient,
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Alert Preferences',
                    subtitle: 'Customize your notifications',
                    onTap: () => context.push('/settings/notifications'),
                    gradient: AppColors.accentGradient,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 16),

              _MenuSection(
                title: 'Preferences',
                items: [
                  _ThemeMenuItem(
                    currentTheme: ref.watch(themeModeProvider),
                    onThemeChanged: (mode) {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                  ),
                  _MenuItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                    gradient: AppColors.primaryGradient,
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Default Location',
                    subtitle: 'Set your area for relevant posts',
                    onTap: () {},
                    gradient: AppColors.secondaryGradient,
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
                    gradient: AppColors.primaryGradient,
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                    gradient: AppColors.secondaryGradient,
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                    gradient: AppColors.accentGradient,
                  ),
                  _MenuItem(
                    icon: Icons.info_outline,
                    title: 'About LostLink',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                    gradient: AppColors.primaryGradient,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Logout button
              if (user != null)
                GestureDetector(
                  onTap: () => _showLogoutConfirmation(context, ref),
                  child: GlassContainer(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    borderRadius: 16,
                    color: AppColors.error.withOpacity(0.1),
                    borderColor: AppColors.error.withOpacity(0.3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

              if (user == null)
                Column(
                  children: [
                    GlassButton(
                      text: 'Sign In',
                      onPressed: () => context.go('/login'),
                      gradient: AppColors.primaryGradient,
                      height: 56,
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      text: 'Create Account',
                      onPressed: () => context.go('/register'),
                      gradient: AppColors.secondaryGradient,
                      height: 56,
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.error.withOpacity(0.2),
                      AppColors.error.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout_rounded, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              const Text('Log Out'),
            ],
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, AppColors.error.withRed(220)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          // Avatar with gradient border
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.secondaryGradient.createShader(bounds),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'G',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Name
          GradientText(
            text: name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            gradient: AppColors.primaryGradient,
          ),

          // Email
          if (email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ),
        ],
      ),
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
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      borderRadius: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: postsCount.toString(),
            label: 'Posts',
            gradient: AppColors.primaryGradient,
          ),
          _StatDivider(),
          _StatItem(
            value: reunionsCount.toString(),
            label: 'Reunited',
            gradient: AppColors.successGradient,
          ),
          _StatDivider(),
          _StatItem(
            value: matchesCount.toString(),
            label: 'Matches',
            gradient: AppColors.secondaryGradient,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Gradient gradient;

  const _StatItem({
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            isDark ? Colors.white24 : Colors.black12,
            Colors.transparent,
          ],
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        GlassContainer(
          borderRadius: 20,
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    ),
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
  final Gradient gradient;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
            ],
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showThemeDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  currentTheme == ThemeMode.dark
                      ? Icons.dark_mode_rounded
                      : currentTheme == ThemeMode.light
                          ? Icons.light_mode_rounded
                          : Icons.brightness_auto_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      _getThemeName(currentTheme),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ],
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.surfaceDark.withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Choose Theme'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                title: 'Light',
                isSelected: currentTheme == ThemeMode.light,
                gradient: AppColors.secondaryGradient,
                onTap: () {
                  onThemeChanged(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                title: 'Dark',
                isSelected: currentTheme == ThemeMode.dark,
                gradient: AppColors.primaryGradient,
                onTap: () {
                  onThemeChanged(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              _ThemeOption(
                icon: Icons.brightness_auto_rounded,
                title: 'System',
                isSelected: currentTheme == ThemeMode.system,
                gradient: AppColors.accentGradient,
                onTap: () {
                  onThemeChanged(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
