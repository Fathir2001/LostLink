/// Environment configuration for LostLink
/// All sensitive values should be loaded from environment variables or .env file
class EnvConfig {
  EnvConfig._();

  /// API base URL for the Node.js backend
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// AI Service URL (FastAPI running locally)
  static const String aiServiceUrl = String.fromEnvironment(
    'AI_SERVICE_URL',
    defaultValue: 'http://localhost:8001',
  );

  /// Cloudinary configuration
  static const String cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: '',
  );

  static const String cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: '',
  );

  /// Sentry DSN for crash reporting (optional)
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Current environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  /// Is production environment
  static bool get isProduction => environment == 'production';

  /// Is development environment
  static bool get isDevelopment => environment == 'development';
}
