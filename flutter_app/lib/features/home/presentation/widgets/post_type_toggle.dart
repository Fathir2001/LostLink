import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../post/domain/models/post.dart';

/// Toggle button for Lost/Found filter with glassmorphism
class PostTypeToggle extends StatelessWidget {
  final PostType? selectedType;
  final ValueChanged<PostType?> onChanged;

  const PostTypeToggle({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              _ToggleButton(
                label: 'All',
                icon: Icons.apps_rounded,
                isSelected: selectedType == null,
                onTap: () => onChanged(null),
              ),
              _ToggleButton(
                label: 'Lost',
                icon: Icons.search_off_rounded,
                isSelected: selectedType == PostType.lost,
                onTap: () => onChanged(PostType.lost),
                gradient: AppColors.lostGradient,
                color: AppColors.lost,
              ),
              _ToggleButton(
                label: 'Found',
                icon: Icons.check_circle_outline_rounded,
                isSelected: selectedType == PostType.found,
                onTap: () => onChanged(PostType.found),
                gradient: AppColors.foundGradient,
                color: AppColors.found,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? color;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.gradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = color ?? AppColors.secondary;
    final buttonGradient = gradient ?? AppColors.secondaryGradient;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? buttonGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
