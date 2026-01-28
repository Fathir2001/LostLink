/// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'LostLink';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Find what matters, reunite what\'s lost';

  // API
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImagesPerPost = 5;
  static const double imageCompressionQuality = 0.8;
  static const int thumbnailSize = 200;

  // Post
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
  static const int minDescriptionLength = 10;

  // Search
  static const int minSearchLength = 2;
  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  // Map
  static const double defaultLatitude = 0.0;
  static const double defaultLongitude = 0.0;
  static const double defaultZoom = 13.0;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const int maxCachedPosts = 100;

  // Animation
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  static const String bookmarksKey = 'bookmarks';

  // Links
  static const String privacyPolicyUrl = 'https://lostlink.app/privacy';
  static const String termsOfServiceUrl = 'https://lostlink.app/terms';
  static const String supportEmail = 'support@lostlink.app';
}
