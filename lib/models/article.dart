class Article {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String sourceName;
  final String url;
  final String imageUrl;
  final DateTime publishedAt;
  final String sentiment; // 'Positive', 'Neutral', 'Negative'

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
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      sourceName: json['sourceName'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      sentiment: json['sentiment'] ?? 'Neutral',
    );
  }
}
