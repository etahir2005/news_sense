import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/bookmarks_service.dart';
import '../widgets/news_card.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarksService _service = BookmarksService();
  List<Article> _savedArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    final cache = await _service.getBookmarks();
    if (mounted) {
      setState(() {
        _savedArticles = cache;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved for Later', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _savedArticles.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No articles saved yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedArticles.length,
              itemBuilder: (context, index) {
                return NewsCard(article: _savedArticles[index]);
              },
            )
    );
  }
}
