class AppConfig {
  // Set at build time via: flutter build web --dart-define=API_URL=https://your-backend.railway.app
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://trading-mlm-backend.up.railway.app/api',
  );
  static const String uploadUrl = String.fromEnvironment(
    'UPLOAD_URL',
    defaultValue: 'https://trading-mlm-backend.up.railway.app',
  );
  static const String appName = 'TradeMLM';
  static const String version = '1.0.0';
}
