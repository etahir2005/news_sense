import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class NewsService {
  final String _apiKey = 'pub_bf238dc1d2904fc186cdbd12799cc10d';
  final String _baseUrl = 'https://newsdata.io/api/1/news';

  // Fetches live news with pagination, categorization, semantic search, and global/local toggle
  Future<Map<String, dynamic>> fetchLiveNews({String? nextPage, String query = '', String category = 'top', bool isGlobal = false}) async {
    String url = '$_baseUrl?apikey=$_apiKey&language=en';
    
    // Toggle between Pakistan and Worldwide
    if (!isGlobal) {
      url += '&country=pk';
    }

    if (category != 'top') {
      url += '&category=$category';
    }
    if (query.isNotEmpty) {
      url += '&q=$query';
    } else if (!isGlobal) {
      // If no query and local, ensure it's heavily pakistan focused
      url += '&q=pakistan';
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
          String title = json['title'] ?? '';
          String desc = json['description'] ?? title;
          
          // Advanced local NLP analysis
          String sentiment = _calculateAdvancedSentiment(desc);
          int credibility = _calculateClickbaitScore(title);
          
          return Article.fromJson(json, sentiment, credibility, isGlobal);
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

  // Advanced NLP algorithm with negations and weighted scores
  String _calculateAdvancedSentiment(String text) {
    if (text.isEmpty) return 'Neutral';
    final lower = text.toLowerCase();

    // Heavy weight negative (Score 3)
    final severeNegative = ['kill', 'dead', 'murder', 'terror', 'bomb', 'war', 'casualty', 'disaster', 'rape', 'assault', 'fatal'];
    // Standard negative (Score 1)
    final standardNegative = ['crash', 'attack', 'inflation', 'crisis', 'decline', 'drop', 'fail', 'bad', 'loss', 'arrest', 'injury', 'court', 'guilty', 'scam', 'fraud'];
    
    // Standard positive (Score 1)
    final positive = ['growth', 'win', 'success', 'boom', 'rise', 'record', 'gain', 'happy', 'invest', 'breakthrough', 'award', 'profit', 'victory', 'celebrate', 'praise', 'recover'];

    // Negation phrases that flip meaning
    final negations = ['not ', 'no ', 'never ', 'stopped ', 'prevented ', 'avoided '];

    int negativeScore = 0;
    int positiveScore = 0;

    for (String word in severeNegative) {
      if (lower.contains(word)) {
        // Check if it's negated (e.g. "prevented terror")
        bool isNegated = negations.any((neg) => lower.contains('$neg$word'));
        if (isNegated) positiveScore += 2; // Flipping severe negative is highly positive
        else negativeScore += 3;
      }
    }

    for (String word in standardNegative) {
      if (lower.contains(word)) {
        bool isNegated = negations.any((neg) => lower.contains('$neg$word'));
        if (isNegated) positiveScore += 1;
        else negativeScore += 1;
      }
    }

    for (String word in positive) {
      if (lower.contains(word)) {
        bool isNegated = negations.any((neg) => lower.contains('$neg$word'));
        if (isNegated) negativeScore += 1;
        else positiveScore += 1;
      }
    }

    if (negativeScore >= 3 && positiveScore <= 1) return 'Negative';
    if (negativeScore > positiveScore * 1.5) return 'Negative';
    if (positiveScore > negativeScore * 1.5) return 'Positive';
    
    return 'Neutral';
  }

  // Analyzes Title for Clickbait / Sensationalism
  // Returns score 0-100 (100 = Highly Credible, 0 = Pure Clickbait)
  int _calculateClickbaitScore(String title) {
    if (title.isEmpty) return 100;
    int score = 100;
    
    // 1. ALL CAPS CHECK (Yelling)
    int upperCount = 0;
    for (int i = 0; i < title.length; i++) {
      if (title[i] == title[i].toUpperCase() && title[i].toLowerCase() != title[i].toUpperCase()) {
        upperCount++;
      }
    }
    if (upperCount > title.length * 0.4) score -= 30; // Deduct heavily if mostly uppercase

    // 2. Excessive Punctuation
    if (title.contains('!!!') || title.contains('?!?')) score -= 20;

    // 3. Clickbait trigger phrases
    final lower = title.toLowerCase();
    final clickbaitPhrases = [
      "you won't believe", "will blow your mind", "shocking", "omg", "this is why", 
      "what happens next", "secret to", "exposed", "mind-blowing", "must see", "viral"
    ];
    
    for (String phrase in clickbaitPhrases) {
      if (lower.contains(phrase)) score -= 25;
    }

    // 4. Questioning titles
    if (title.endsWith('?') && lower.split(' ').length < 8) score -= 10; // Short questions are often clickbait

    return score.clamp(0, 100);
  }
}
