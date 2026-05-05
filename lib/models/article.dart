import 'dart:convert';
import 'package:flutter/foundation.dart';

class Article {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String sourceName;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final String sentiment;
  final int credibilityScore;
  final bool isGlobal;

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.sourceName,
    required this.url,
    required this.imageUrl,
    required this.publishedAt,
    required this.sentiment,
    required this.credibilityScore,
    required this.isGlobal,
  });

  factory Article.fromJson(Map<String, dynamic> json, String calculatedSentiment, int calculatedCredibility, bool global) {
    String desc = json['description'] ?? 'No description available.';
    // Graceful Image Fallbacks
    String? img = json['image_url'];
    if (img == null || img.isEmpty || img.contains('null')) {
      img = 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800&auto=format&fit=crop';
    }
    
    // On web, use a CORS proxy to load images
    if (kIsWeb && !img.contains('corsproxy')) {
      img = 'https://corsproxy.io/?${Uri.encodeComponent(img)}';
    }
    
    return Article(
      id: json['article_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'No Title',
      summary: desc, 
      content: json['content'] ?? '',
      sourceName: json['source_id'] ?? 'NewsProvider',
      url: json['link'] ?? '',
      imageUrl: img,
      publishedAt: DateTime.tryParse(json['pubDate'] ?? '') ?? DateTime.now(),
      sentiment: calculatedSentiment,
      credibilityScore: calculatedCredibility,
      isGlobal: global,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article_id': id,
      'title': title,
      'description': summary,
      'content': content,
      'source_id': sourceName,
      'link': url,
      'image_url': imageUrl,
      'pubDate': publishedAt.toIso8601String(),
      'sentiment': sentiment,
      'credibilityScore': credibilityScore,
      'isGlobal': isGlobal,
    };
  }
}
