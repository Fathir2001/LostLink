import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            // Animated background circles
            ..._buildBackgroundCircles(),
            
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_controller, _pulseController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo with glass effect
                        Transform.scale(
                          scale: _scaleAnimation.value * _pulseAnimation.value,
                          child: _buildLogo(),
                        ),

                        SizedBox(height: 32 + _slideAnimation.value),

                        // App name with gradient
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: _buildAppName(),
                        ),

                        const SizedBox(height: 12),

                        // Tagline
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value * 1.5),
                          child: _buildTagline(),
                        ),

                        const SizedBox(height: 80),

                        // Loading indicator
                        Transform.translate(
                          offset: Offset(0, _slideAnimation.value * 2),
                          child: _buildLoadingIndicator(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundCircles() {
    return [
      // Top right circle
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_pulseAnimation.value - 1) * 0.5,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.3),
                      AppColors.secondary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Bottom left circle
      Positioned(
        bottom: -150,
        left: -150,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.08 - (_pulseAnimation.value - 1) * 0.5,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primarySoft.withOpacity(0.3),
                      AppColors.primarySoft.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 60,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if logo not found
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.secondary,
                          AppColors.accent,
                        ],
                      ).createShader(bounds);
                    },
                    child: const Icon(
                      Icons.location_searching,
                      size: 70,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Lost',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                AppColors.secondary,
                AppColors.accent,
              ],
            ).createShader(bounds);
          },
          child: Text(
            'Link',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
              shadows: [
                Shadow(
                  color: AppColors.secondary.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Text(
      'Reuniting What\'s Lost',
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.secondary.withOpacity(0.8),
        ),
      ),
    );
  }
}
