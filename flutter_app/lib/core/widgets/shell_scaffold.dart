import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Shell scaffold with bottom navigation
class ShellScaffold extends ConsumerWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we're on a wide screen (web/tablet)
        final isWideScreen = constraints.maxWidth >= 800;

        if (isWideScreen) {
          return _buildWideLayout(context, ref);
        }

        return _buildMobileLayout(context, ref);
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createPost),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildWideLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Side navigation rail
          _SideNavRail(),
          // Divider
          const VerticalDivider(width: 1),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _getSelectedIndex(location),
        onTap: (index) => _onNavTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 40), // Placeholder for FAB
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.alerts)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.search);
        break;
      case 2:
        // Center button - handled by FAB
        context.push(AppRoutes.createPost);
        break;
      case 3:
        context.go(AppRoutes.alerts);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }
}

class _SideNavRail extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);

    return NavigationRail(
      backgroundColor: theme.colorScheme.surface,
      selectedIndex: _getSelectedIndex(location),
      onDestinationSelected: (index) => _onNavTap(context, index),
      labelType: NavigationRailLabelType.all,
      leading: Column(
        children: [
          const SizedBox(height: 16),
          // Logo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.link,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 24),
          // Create post button
          FloatingActionButton(
            onPressed: () => context.push(AppRoutes.createPost),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
        ],
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: Text('Alerts'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.search)) return 1;
    if (location.startsWith(AppRoutes.alerts)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.search);
        break;
      case 2:
        context.go(AppRoutes.alerts);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
