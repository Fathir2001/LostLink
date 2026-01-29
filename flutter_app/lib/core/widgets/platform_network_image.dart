import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_colors.dart';

/// A network image widget that handles platform differences.
/// Uses Image.network on web (better CORS handling) and CachedNetworkImage on native.
class PlatformNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PlatformNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder = Container(
      color: AppColors.dividerLight,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.secondary,
        ),
      ),
    );

    final defaultError = Container(
      color: AppColors.dividerLight,
      child: const Icon(Icons.image_not_supported_outlined),
    );

    if (kIsWeb) {
      // On web, use Image.network which handles CORS better
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? defaultPlaceholder;
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? defaultError;
        },
      );
    } else {
      // On native platforms, use CachedNetworkImage for caching
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => placeholder ?? defaultPlaceholder,
        errorWidget: (context, url, error) => errorWidget ?? defaultError,
      );
    }
  }
}

/// A network image provider that works across platforms
ImageProvider platformNetworkImageProvider(String imageUrl) {
  if (kIsWeb) {
    return NetworkImage(imageUrl);
  } else {
    return CachedNetworkImageProvider(imageUrl);
  }
}
