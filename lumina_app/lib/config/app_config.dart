class AppConfig {
  AppConfig._();

  /// URL base de la API Ehily (colección Bruno "Ehily API CECAR - Gestor").
  /// Se puede cambiar con: flutter run --dart-define=API_BASE_URL=https://...
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ehily.cecar.cloud',
  );

  static const nombreApp = 'Lumina Beauty Center';
  static const version = '1.0.0';
}
