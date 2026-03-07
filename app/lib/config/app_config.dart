class AppConfig {
  static const String appName = 'Ghar';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator localhost
  );
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // Visitor auto-expiry timeout
  static const Duration visitorTimeout = Duration(minutes: 5);

  // Token refresh threshold
  static const Duration tokenRefreshThreshold = Duration(minutes: 2);
}
