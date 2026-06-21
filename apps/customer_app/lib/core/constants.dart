class AppConstants {
  static const String appName = 'Swift Egypt';
  static const String appNameAr = 'سويفت إيجيبت';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String storageKeyToken = 'auth_token';
  static const String storageKeyUser = 'user_data';
  static const String storageKeyLocale = 'locale_preference';
  static const String pendingActionsKey = 'pending_actions';

  static const List<String> supportedLocales = ['ar', 'en'];
  static const String defaultLocale = 'ar';
}
