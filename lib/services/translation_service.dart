import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static final Map<String, String> _cache = {};

  /// Translates English text to Urdu using Google Translate (free endpoint)
  static Future<String> translateToUrdu(String text) async {
    if (_cache.containsKey(text)) return _cache[text]!;

    try {
      final encoded = Uri.encodeComponent(text);
      final url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=ur&dt=t&q=$encoded';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String translated = '';
        for (var sentence in data[0]) {
          if (sentence[0] != null) translated += sentence[0];
        }
        _cache[text] = translated;
        return translated;
      }
      return 'ترجمہ دستیاب نہیں ہے';
    } catch (e) {
      return 'ترجمہ دستیاب نہیں ہے';
    }
  }
}
