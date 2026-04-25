import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String _apiKey = 'pub_bf238dc1d2904fc186cdbd12799cc10d';
  final String _baseUrl = 'https://newsdata.io/api/1/news';

  // Fetches live news with pagination, categorization and semantic search
  Future<Map<String, dynamic>> fetchLiveNews({String? nextPage, String query = 'pakistan', String category = 'top'}) async {
    String url = '$_baseUrl?apikey=$_apiKey&country=pk&language=en';
    
    if (category != 'top') {
      url += '&category=$category';
    }
    if (query.isNotEmpty) {
      url += '&q=$query';
    }
    
    if (nextPage != null && nextPage.isNotEmpty) {
      url += '&page=$nextPage';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> results = data['results'] ?? [];
        String? nextToken = data['nextPage'];

        List<Article> articles = results.map((json) {
          // Calculate Sentiment Locally (Frugal AI)
          String desc = json['description'] ?? json['title'] ?? '';
          String sentiment = _calculateSentiment(desc);
          return Article.fromJson(json, sentiment);
        }).toList();

        return {
          'articles': articles,
          'nextPage': nextToken,
        };
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  // Frugal Local AI algorithm to simulate Sentiment without paying for API calls
  String _calculateSentiment(String text) {
    if (text.isEmpty) return 'Neutral';
    final lower = text.toLowerCase();

    final negativeKeywords = ['kill', 'crash', 'dead', 'attack', 'inflation', 'crisis', 'terror', 'decline', 'drop', 'fail', 'bad', 'loss', 'arrest'];
    final positiveKeywords = ['growth', 'win', 'success', 'boom', 'rise', 'record', 'gain', 'happy', 'invest', 'breakthrough', 'award', 'profit'];

    int negativeScore = negativeKeywords.where((k) => lower.contains(k)).length;
    int positiveScore = positiveKeywords.where((k) => lower.contains(k)).length;

    if (negativeScore > positiveScore) return 'Negative';
    if (positiveScore > negativeScore) return 'Positive';
    return 'Neutral';
  }
}
