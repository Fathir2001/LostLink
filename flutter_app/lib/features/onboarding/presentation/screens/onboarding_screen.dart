import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.search,
      title: 'Find What\'s Lost',
      description:
          'Search through thousands of lost and found items in your area. Our AI-powered system helps you find matches quickly.',
      gradient: AppColors.lostGradient,
      color: AppColors.lost,
    ),
    _OnboardingPageData(
      icon: Icons.auto_awesome,
      title: 'AI-Powered Matching',
      description:
          'Our advanced AI automatically matches lost items with found reports. Get notified when there\'s a potential match.',
      gradient: AppColors.primaryGradient,
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      icon: Icons.photo_camera,
      title: 'Easy Posting',
      description:
          'Just take a photo and our AI will extract all the details. Post items in seconds, not minutes.',
      gradient: AppColors.secondaryGradient,
      color: AppColors.secondary,
    ),
    _OnboardingPageData(
      icon: Icons.favorite,
      title: 'Reunite with Joy',
      description:
          'Help others find their precious belongings. Every reunion is a story of kindness and community.',
      gradient: AppColors.foundGradient,
      color: AppColors.found,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.primaryDark.withOpacity(0.3)]
                : [AppColors.backgroundLight, AppColors.primaryLight.withOpacity(0.1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    borderRadius: 12,
                    padding: EdgeInsets.zero,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _GlassOnboardingPage(
                      data: _pages[index],
                      isActive: _currentPage == index,
                    );
                  },
                ),
              ),

              // Bottom section
              _GlassBottomSection(
                currentPage: _currentPage,
                totalPages: _pages.length,
                pageGradient: _pages[_currentPage].gradient,
                onNextPressed: _nextPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.color,
  });
}

class _GlassOnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  final bool isActive;

  const _GlassOnboardingPage({
    required this.data,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass icon container
          _GlassIconOrb(
            icon: data.icon,
            gradient: data.gradient,
            color: data.color,
          )
              .animate(target: isActive ? 1 : 0)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
                duration: 600.ms,
              )
              .fadeIn(),

          const SizedBox(height: 48),

          // Title with gradient
          GradientText(
            text: data.title,
            gradient: data.gradient,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 20),

          // Description in glass container
          GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Text(
              data.description,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          )
              .animate(target: isActive ? 1 : 0)
              .fadeIn(delay: 300.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}

class _GlassIconOrb extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final Color color;

  const _GlassIconOrb({
    required this.icon,
    required this.gradient,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Inner gradient orb
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBottomSection extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final LinearGradient pageGradient;
  final VoidCallback onNextPressed;

  const _GlassBottomSection({
    required this.currentPage,
    required this.totalPages,
    required this.pageGradient,
    required this.onNextPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.7),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppColors.dividerLight,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page indicators
              Row(
                children: List.generate(
                  totalPages,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(right: 10),
                    width: currentPage == index ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: currentPage == index ? pageGradient : null,
                      color: currentPage == index
                          ? null
                          : (isDark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: currentPage == index
                          ? [
                              BoxShadow(
                                color: pageGradient.colors.first.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),

              // Next/Get Started button
              GestureDetector(
                onTap: onNextPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: pageGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: pageGradient.colors.first.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentPage < totalPages - 1 ? 'Next' : 'Get Started',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        currentPage < totalPages - 1
                            ? Icons.arrow_forward
                            : Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
