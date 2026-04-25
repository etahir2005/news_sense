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
  List<Article> _saved = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load(); // Refresh when navigating back
  }

  Future<void> _load() async {
    final cache = await _service.getBookmarks();
    if (mounted) setState(() { _saved = cache; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Articles', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _saved.isEmpty
          ? Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bookmark_outline, size: 80, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 16),
                const Text('No saved articles yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Tap the bookmark icon on any article to save it.', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ]),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _saved.length,
                itemBuilder: (context, index) => NewsCard(article: _saved[index]),
              ),
            ),
    );
  }
}
