import 'package:flutter/material.dart';
import '../models/article.dart';

class NewsCard extends StatelessWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'Positive':
        return Colors.green;
      case 'Negative':
        return Colors.redAccent;
      case 'Neutral':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image placeholder with source name
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: NetworkImage(article.imageUrl), // Mock network logic
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                article.sourceName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline
                Text(
                  article.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Sentiment Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSentimentColor(article.sentiment).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getSentimentColor(article.sentiment)),
                  ),
                  child: Text(
                    article.sentiment,
                    style: TextStyle(
                      color: _getSentimentColor(article.sentiment),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // AI Insight Expansion
                ExpansionTile(
                  title: const Text('✨ AI Insight: Why This Matters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [
                    Text(
                      article.summary,
                      style: const TextStyle(color: Colors.black87, height: 1.4),
                    ),
                  ],
                ),
                
                const Divider(),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${article.publishedAt.hour}h ago',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () {},
                      color: Colors.blueAccent,
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
