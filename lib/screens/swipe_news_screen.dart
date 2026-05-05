import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../services/bookmarks_service.dart';
import '../services/stats_service.dart';
import '../models/article.dart';
import 'article_webview_screen.dart';

class SwipeNewsScreen extends StatefulWidget {
  const SwipeNewsScreen({super.key});

  @override
  State<SwipeNewsScreen> createState() => _SwipeNewsScreenState();
}

class _SwipeNewsScreenState extends State<SwipeNewsScreen> {
  final PageController _pageController = PageController();

  void _share(Article article) {
    Share.share('📰 ${article.title}\n\n🔗 ${article.url}\n\nFound on NewsSense Swipe Mode!');
  }

  void _open(Article article) {
    if (article.url.isNotEmpty) {
      StatsService().logArticleRead(article.id, article.sourceName, article.summary.split(' ').length);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleWebViewScreen(url: article.url, title: article.sourceName)));
    }
  }

  void _save(Article article, BuildContext context) async {
    bool saved = await BookmarksService().isBookmarked(article.id);
    if (!saved) {
      await BookmarksService().saveBookmark(article);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('📌 Saved to Bookmarks!'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.articles.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (provider.articles.isEmpty) {
            return const Center(child: Text("No news to swipe.", style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical, // TikTok style vertical swiping
            itemCount: provider.articles.length,
            onPageChanged: (index) {
              if (index >= provider.articles.length - 3) {
                provider.fetchMoreNews(); // Infinite scroll
              }
            },
            itemBuilder: (context, index) {
              final article = provider.articles[index];
              return Dismissible(
                key: Key(article.id),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Right swipe = Save
                    _save(article, context);
                  }
                  // Move to next page vertically
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  return false; // Spring back horizontally
                },
                background: Container(
                  color: Colors.green.withOpacity(0.8),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 40),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bookmark_add, color: Colors.white, size: 60),
                      SizedBox(height: 10),
                      Text('SAVE', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  color: Colors.red.withOpacity(0.8),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 40),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: Colors.white, size: 60),
                      SizedBox(height: 10),
                      Text('DISMISS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                child: _buildSwipeCard(article, context),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSwipeCard(Article article, BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.network(
          article.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
        ),
        
        // Gradient overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Source Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF667eea), borderRadius: BorderRadius.circular(20)),
                  child: Text(article.sourceName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  article.title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 12),
                
                // Summary
                Text(
                  article.summary,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),
                
                // Actions (Swipe hint)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.swipe, color: Colors.white54, size: 20),
                        SizedBox(width: 8),
                        Text('Swipe ⬅️ ➡️ or ⬆️', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _open(article),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Read Full'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // padding for bottom nav
              ],
            ),
          ),
        ),

        // Right side action buttons
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFloatingAction(Icons.bookmark_add_outlined, 'Save', () => _save(article, context)),
              const SizedBox(height: 24),
              _buildFloatingAction(Icons.share_outlined, 'Share', () => _share(article)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingAction(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.black.withOpacity(0.5),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
