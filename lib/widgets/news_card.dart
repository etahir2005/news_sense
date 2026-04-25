import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmarks_service.dart';
import '../screens/article_webview_screen.dart';

class NewsCard extends StatefulWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
        content: Text(_isSaved ? '📌 Saved to Bookmarks!' : 'Removed from Bookmarks.'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Color _getSentimentColor(String sentiment) {
    if (sentiment == 'Positive') return const Color(0xFF2ECC71);
    if (sentiment == 'Negative') return const Color(0xFFE74C3C);
    return const Color(0xFF95A5A6);
  }

  IconData _getSentimentIcon(String sentiment) {
    if (sentiment == 'Positive') return Icons.trending_up;
    if (sentiment == 'Negative') return Icons.trending_down;
    return Icons.trending_flat;
  }

  void _openArticle() {
    if (widget.article.url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleWebViewScreen(
            url: widget.article.url,
            title: widget.article.sourceName,
          ),
        ),
      );
    }
  }

  void _shareArticle() {
    Share.share(
      '📰 ${widget.article.title}\n\n'
      '🤖 AI Sentiment: ${widget.article.sentiment}\n\n'
      '🔗 ${widget.article.url}\n\n'
      'Shared via NewsSense — Smart News, Less Noise.',
    );
  }

  String _getReadingTime() {
    int wordCount = widget.article.summary.split(' ').length;
    int minutes = (wordCount / 200).ceil();
    if (minutes < 1) minutes = 1;
    return '$minutes min read';
  }

  String _getTimeSincePublished() {
    final diff = DateTime.now().difference(widget.article.publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _openArticle,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image with gradient overlay
              Stack(
                children: [
                  Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Image.network(
                      widget.article.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blueAccent.withOpacity(0.3), Colors.deepPurple.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.newspaper, size: 60, color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? const Color(0xFF1E1E2E) : Colors.white).withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Source badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.article.sourceName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                  // Time badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeSincePublished(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sentiment + Reading Time Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getSentimentColor(widget.article.sentiment).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getSentimentIcon(widget.article.sentiment), size: 14, color: _getSentimentColor(widget.article.sentiment)),
                              const SizedBox(width: 4),
                              Text(
                                widget.article.sentiment,
                                style: TextStyle(
                                  color: _getSentimentColor(widget.article.sentiment),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book, size: 14, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(
                                _getReadingTime(),
                                style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      widget.article.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // AI Insight
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.blueAccent).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 6),
                              Text(
                                'AI Insight',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent.shade700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.article.summary,
                            style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openArticle,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Read Full', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              key: ValueKey(_isSaved),
                              size: 22,
                            ),
                          ),
                          onPressed: _toggleBookmark,
                          color: _isSaved ? Colors.blueAccent : Colors.grey,
                          style: IconButton.styleFrom(
                            backgroundColor: (_isSaved ? Colors.blueAccent : Colors.grey).withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 22),
                          onPressed: _shareArticle,
                          color: Colors.grey,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
