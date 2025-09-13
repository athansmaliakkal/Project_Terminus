class ApiConfig {
  static const String googleMapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'YOUR_DEFAULT_FALLBACK_KEY_IF_ANY',
  );

  static const String baseUrl = "https://api.yourserver.com/v1";
 
  static const String openWeatherApiKey = String.fromEnvironment('OPEN_WEATHER_API_KEY');
}