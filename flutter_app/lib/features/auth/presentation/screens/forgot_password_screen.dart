import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            _emailController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.heroGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Icon
          Center(
            child: GlassContainer(
              width: 100,
              height: 100,
              borderRadius: 30,
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 32),

          // Title
          GradientText(
            text: 'Forgot Password?',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            gradient: AppColors.primaryGradient,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 12),

          Text(
            'Enter your email and we\'ll send you\na link to reset your password',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 40),

          // Email field
          GlassTextField(
            controller: _emailController,
            hint: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

          const SizedBox(height: 32),

          // Submit button
          GlassButton(
            text: 'Send Reset Link',
            onPressed: _requestReset,
            isLoading: _isLoading,
            gradient: AppColors.primaryGradient,
            height: 56,
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 24),

          // Back to login
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  GradientText(
                    text: 'Back to Login',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    gradient: AppColors.secondaryGradient,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),

        // Success icon
        Center(
          child: GlassContainer(
            width: 120,
            height: 120,
            borderRadius: 35,
            color: AppColors.success.withOpacity(0.2),
            child: Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.success,
              size: 60,
            ),
          ),
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

        const SizedBox(height: 40),

        GradientText(
          text: 'Check Your Email',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          gradient: AppColors.successGradient,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 16),

        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          child: Column(
            children: [
              Icon(
                Icons.email_outlined,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                size: 24,
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a password reset link to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _emailController.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

        const SizedBox(height: 40),

        GlassButton(
          text: 'Back to Login',
          onPressed: () => context.pop(),
          gradient: AppColors.primaryGradient,
          height: 56,
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),

        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _emailSent = false);
            },
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              borderRadius: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Didn\'t receive email? Try again',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
