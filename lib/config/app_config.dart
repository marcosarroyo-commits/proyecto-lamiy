class AppConfig {
  AppConfig._();

  
  
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ehily.cecar.cloud',
  );

  static const nombreApp = 'Lumina Beauty Center';
  static const version = '1.0.0';
}
