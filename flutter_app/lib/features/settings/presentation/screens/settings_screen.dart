import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.primaryDark.withOpacity(0.2)]
                : [AppColors.backgroundLight, AppColors.primaryLight.withOpacity(0.1)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Glass App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.white.withOpacity(0.7),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : AppColors.dividerLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              leading: Container(
                margin: const EdgeInsets.all(8),
                child: GlassContainer(
                  borderRadius: 12,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              title: GradientText(
                text: 'Settings',
                gradient: AppColors.primaryGradient,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Notifications section
                    _GlassSettingsSection(
                      title: 'Notifications',
                      icon: Icons.notifications_outlined,
                      gradient: AppColors.primaryGradient,
                      children: [
                        _GlassSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Push Notifications',
                          subtitle: 'Get notified about matches and messages',
                          value: true,
                          onChanged: (value) {},
                        ),
                        _GlassSwitchTile(
                          icon: Icons.email_outlined,
                          title: 'Email Notifications',
                          subtitle: 'Receive updates via email',
                          value: false,
                          onChanged: (value) {},
                        ),
                        _GlassSwitchTile(
                          icon: Icons.auto_awesome,
                          title: 'Match Alerts',
                          subtitle: 'Get instant alerts when AI finds a match',
                          value: true,
                          onChanged: (value) {},
                        ),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Appearance section
                    _GlassSettingsSection(
                      title: 'Appearance',
                      icon: Icons.palette_outlined,
                      gradient: AppColors.secondaryGradient,
                      children: [
                        _GlassThemeTile(
                          currentTheme: ref.watch(themeModeProvider),
                          onChanged: (mode) {
                            ref.read(themeModeProvider.notifier).setThemeMode(mode);
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Privacy section
                    _GlassSettingsSection(
                      title: 'Privacy',
                      icon: Icons.shield_outlined,
                      gradient: AppColors.successGradient,
                      children: [
                        _GlassSwitchTile(
                          icon: Icons.visibility_outlined,
                          title: 'Show Profile',
                          subtitle: 'Allow others to view your profile',
                          value: true,
                          onChanged: (value) {},
                        ),
                        _GlassSwitchTile(
                          icon: Icons.phone_outlined,
                          title: 'Show Phone Number',
                          subtitle: 'Display phone on your posts',
                          value: false,
                          onChanged: (value) {},
                        ),
                        _GlassNavigationTile(
                          icon: Icons.block_outlined,
                          title: 'Blocked Users',
                          onTap: () {},
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Data section
                    _GlassSettingsSection(
                      title: 'Data & Storage',
                      icon: Icons.storage_outlined,
                      gradient: AppColors.lostGradient,
                      children: [
                        _GlassNavigationTile(
                          icon: Icons.download_outlined,
                          title: 'Download My Data',
                          onTap: () {},
                        ),
                        _GlassNavigationTile(
                          icon: Icons.delete_sweep_outlined,
                          title: 'Clear Cache',
                          subtitle: '12.5 MB',
                          onTap: () => _showClearCacheDialog(context),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // About section
                    _GlassSettingsSection(
                      title: 'About',
                      icon: Icons.info_outline,
                      gradient: AppColors.foundGradient,
                      children: [
                        _GlassNavigationTile(
                          icon: Icons.smartphone_outlined,
                          title: 'App Version',
                          subtitle: '1.0.0 (Build 1)',
                          onTap: () {},
                        ),
                        _GlassNavigationTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          onTap: () {},
                        ),
                        _GlassNavigationTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _GlassNavigationTile(
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
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.lostGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_sweep, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Clear Cache?'),
          ],
        ),
        content: Text(
          'This will clear cached images and data. Your posts and settings will not be affected.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
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
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cache cleared'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final List<Widget> children;

  const _GlassSettingsSection({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _GlassSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlassSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: ShaderMask(
        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.primary.withOpacity(0.4),
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _GlassNavigationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _GlassNavigationTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: ShaderMask(
        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      onTap: onTap,
    );
  }
}

class _GlassThemeTile extends StatelessWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onChanged;

  const _GlassThemeTile({
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: ShaderMask(
        shaderCallback: (bounds) => AppColors.secondaryGradient.createShader(bounds),
        child: Icon(
          currentTheme == ThemeMode.dark
              ? Icons.dark_mode
              : currentTheme == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        'Theme',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        _getThemeName(currentTheme),
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.palette, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Choose Theme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GlassThemeOption(
              icon: Icons.light_mode,
              title: 'Light',
              isSelected: currentTheme == ThemeMode.light,
              onTap: () {
                onChanged(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _GlassThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark',
              isSelected: currentTheme == ThemeMode.dark,
              onTap: () {
                onChanged(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _GlassThemeOption(
              icon: Icons.brightness_auto,
              title: 'System',
              isSelected: currentTheme == ThemeMode.system,
              onTap: () {
                onChanged(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GlassThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white)
            else
              Icon(
                Icons.circle_outlined,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }
}
