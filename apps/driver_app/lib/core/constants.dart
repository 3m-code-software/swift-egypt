class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static const String apiBaseUrlDev = String.fromEnvironment(
    'API_BASE_URL_DEV',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String localeKey = 'app_locale';
  static const String pendingActionsKey = 'pending_actions';

  static const int locationUpdateIntervalSeconds = 120;
  static const int syncRetryIntervalSeconds = 30;
  static const int mapZoomDefault = 14.0;
}
