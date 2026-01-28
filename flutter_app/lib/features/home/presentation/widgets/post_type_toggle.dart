import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../post/domain/models/post.dart';

/// Toggle button for Lost/Found filter
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'All',
            isSelected: selectedType == null,
            onTap: () => onChanged(null),
          ),
          _ToggleButton(
            label: 'Lost',
            isSelected: selectedType == PostType.lost,
            onTap: () => onChanged(PostType.lost),
            color: AppColors.lost,
          ),
          _ToggleButton(
            label: 'Found',
            isSelected: selectedType == PostType.found,
            onTap: () => onChanged(PostType.found),
            color: AppColors.found,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? buttonColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
