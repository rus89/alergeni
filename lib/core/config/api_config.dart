class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://77.46.150.200/api/opendata',
  );

  static const Duration requestTimeout = Duration(
    seconds: int.fromEnvironment(
      'API_REQUEST_TIMEOUT_SECONDS',
      defaultValue: 10,
    ),
  );

  static const int maxRetries = int.fromEnvironment(
    'API_MAX_RETRIES',
    defaultValue: 3,
  );

  static const bool isDebugMode = bool.fromEnvironment(
    'API_DEBUG_MODE',
    defaultValue: false,
  );

  static const bool enableLogging = bool.fromEnvironment(
    'API_ENABLE_LOGGING',
    defaultValue: false,
  );
}
