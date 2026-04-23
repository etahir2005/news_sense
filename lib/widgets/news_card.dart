import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/bookmarks_service.dart';

class NewsCard extends StatefulWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    bool saved = await BookmarksService().isBookmarked(widget.article.id);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isSaved) {
      await BookmarksService().removeBookmark(widget.article.id);
    } else {
      await BookmarksService().saveBookmark(widget.article);
    }
    setState(() => _isSaved = !_isSaved);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSaved ? 'Saved to Bookmarks!' : 'Removed from Bookmarks.'),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  Color _getSentimentColor(String sentiment) {
    if (sentiment == 'Positive') return Colors.green;
    if (sentiment == 'Negative') return Colors.redAccent;
    return Colors.blueGrey;
  }

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(widget.article.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch url');
    }
  }

  void _shareArticle() {
    Share.share('Read this on NewsSense (AI Insight: \${widget.article.sentiment}): \${widget.article.title}\\n\\n\${widget.article.url}');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchUrl,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Elegant Image Fallback UI handled inside Image.network errorBuilder
            Container(
              height: 200,
              decoration: const BoxDecoration(color: Colors.grey),
              child: Image.network(
                widget.article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.white54),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSentimentColor(widget.article.sentiment).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getSentimentColor(widget.article.sentiment)),
                        ),
                        child: Text(
                          widget.article.sentiment,
                          style: TextStyle(
                            color: _getSentimentColor(widget.article.sentiment),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(widget.article.sourceName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.article.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: const Text('✨ AI Insight: Why This Matters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    children: [
                      Text(
                        widget.article.summary,
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Read full article', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, size: 24),
                            onPressed: _toggleBookmark,
                            color: _isSaved ? Colors.blueAccent : Colors.grey,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 24),
                            onPressed: _shareArticle,
                            color: Colors.grey,
                          )
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
