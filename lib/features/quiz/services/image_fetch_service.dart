import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';

class ImageFetchService {
  static const _tag = 'Briefed/ImageFetch';

  static Future<String?> fetchForQuery(String query) async {
    const key = ApiConfig.unsplashAccessKey;
    if (key.isEmpty) return null;

    try {
      final words = query.trim().split(RegExp(r'\s+')).take(3).join(' ');
      final uri =
          Uri.parse('https://api.unsplash.com/search/photos').replace(
        queryParameters: {
          'query': words,
          'per_page': '1',
          'client_id': key,
        },
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List? ?? [];
      if (results.isEmpty) return null;
      return results.first['urls']?['regular'] as String?;
    } catch (e) {
      dev.log('Unsplash fetch failed: $e', name: _tag);
      return null;
    }
  }
}
