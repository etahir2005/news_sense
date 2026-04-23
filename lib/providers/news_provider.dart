import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _service = NewsService();

  List<Article> _articles = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String? _nextPageToken;
  String? _errorMessage;

  // Advanced Filters
  String _currentCategory = 'top';
  String _currentSearch = 'pakistan';

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _nextPageToken != null;
  String get currentCategory => _currentCategory;

  NewsProvider() {
    fetchInitialNews();
  }

  void setCategory(String category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    _currentSearch = ''; // Clear search when switching category strictly
    fetchInitialNews();
  }

  void setSearch(String query) {
    if (query.isEmpty) {
      _currentSearch = 'pakistan'; // Default falback
    } else {
      _currentSearch = query;
    }
    fetchInitialNews();
  }

  Future<void> fetchInitialNews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.fetchLiveNews(
        query: _currentSearch,
        category: _currentCategory,
      );
      _articles = response['articles'];
      _nextPageToken = response['nextPage'];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreNews() async {
    if (_isFetchingMore || _nextPageToken == null) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final response = await _service.fetchLiveNews(
        query: _currentSearch,
        category: _currentCategory,
        nextPage: _nextPageToken,
      );
      _articles.addAll(response['articles']);
      _nextPageToken = response['nextPage'];
    } catch (e) {
      // Intentional silent catch for pagination boundaries
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }
}
