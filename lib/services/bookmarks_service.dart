import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarksService {
  static const String _key = 'saved_bookmarks';

  Future<List<Article>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null || data.isEmpty) return [];

    List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map<Article>((json) => Article.fromJson(json, 'Saved', 100, false)).toList();
  }

  Future<void> saveBookmark(Article article) async {
    final prefs = await SharedPreferences.getInstance();
    List<Article> current = await getBookmarks();
    
    // Prevent duplicates
    if (!current.any((a) => a.id == article.id)) {
      current.add(article);
      List<Map<String, dynamic>> jsonList = current.map((a) => a.toJson()).toList();
      await prefs.setString(_key, jsonEncode(jsonList));
    }
  }

  Future<void> removeBookmark(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    List<Article> current = await getBookmarks();
    
    current.removeWhere((a) => a.id == articleId);
    List<Map<String, dynamic>> jsonList = current.map((a) => a.toJson()).toList();
    await prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<bool> isBookmarked(String articleId) async {
    List<Article> current = await getBookmarks();
    return current.any((a) => a.id == articleId);
  }
}
