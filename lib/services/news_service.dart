import 'dart:async';
import '../models/article.dart';

class NewsService {
  // Simulates a network delay and returns mock data that is perfectly structured
  // for the MVP presentation. To integrate a real API later, just replace
  // this mock list with an http.get call and JSON parsing.
  Future<List<Article>> fetchTopHeadlines() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request

    return [
      Article(
        id: '1',
        title: 'Global Markets Rally as Tech Stocks Surge',
        summary: 'Technology stocks led a broad market rally today, pushing major indices to record highs amid strong earnings reports.',
        content: 'Full article content here...',
        sourceName: 'Financial Times',
        url: 'https://example.com/1',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&auto=format&fit=crop',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
        sentiment: 'Positive',
      ),
      Article(
        id: '2',
        title: 'New Climate Report Warns of Rising Sea Levels',
        summary: 'A new UN environmental report details accelerating ice melt and warns coastal cities must prepare for significant sea level rise.',
        content: 'Full article content here...',
        sourceName: 'Global News',
        url: 'https://example.com/2',
        imageUrl: 'https://images.unsplash.com/photo-1561484930-998b6a7b22e8?w=800&auto=format&fit=crop',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
        sentiment: 'Negative',
      ),
      Article(
        id: '3',
        title: 'AI Breakthroughs Shake Up the Software Industry',
        summary: 'Recent advancements in generative AI are restructuring software development pipelines, raising both excitement and job security concerns.',
        content: 'Full article content here...',
        sourceName: 'TechDaily',
        url: 'https://example.com/3',
        imageUrl: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&auto=format&fit=crop',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
        sentiment: 'Neutral',
      ),
      Article(
        id: '4',
        title: 'Major Merger Announced in the Automotive Sector',
        summary: 'Two leading EV manufacturers have agreed to merge in a \$30B deal, aiming to dominate the electric vehicle market globally.',
        content: 'Full article content here...',
        sourceName: 'Auto Insider',
        url: 'https://example.com/4',
        imageUrl: 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&auto=format&fit=crop',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
        sentiment: 'Positive',
      ),
      Article(
        id: '5',
        title: 'Supply Chain Disruptions Cause Retail Shortages',
        summary: 'Unprecedented port delays are causing severe shortages for popular retail items ahead of the holiday season.',
        content: 'Full article content here...',
        sourceName: 'Commerce Weekly',
        url: 'https://example.com/5',
        imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8ed7cace26?w=800&auto=format&fit=crop',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        sentiment: 'Negative',
      ),
    ];
  }
}
