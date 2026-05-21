class ApiConfig {
  static const String currentsApiKey =
      String.fromEnvironment('CURRENTS_API_KEY');
  static const String guardianApiKey =
      String.fromEnvironment('GUARDIAN_API_KEY');
  static const String newsdataApiKey =
      String.fromEnvironment('NEWSDATA_API_KEY');
  static const String unsplashAccessKey =
      String.fromEnvironment('UNSPLASH_ACCESS_KEY');
  static const String groqApiKey = String.fromEnvironment('GROQ_API_KEY');

  static const String currentsBaseUrl = 'https://api.currentsapi.services/v1';
  static const String guardianBaseUrl = 'https://content.guardianapis.com';
  static const String newsdataBaseUrl = 'https://newsdata.io/api/1';
}
