import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';

class BookmarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Get Bookmarks from Firestore
  Future<List<Article>> getBookmarks() async {
    if (_uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('bookmarks')
        .orderBy('savedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return Article.fromJson(doc.data(), 'Saved', 100, false);
    }).toList();
  }

  // Save Bookmark to Firestore
  Future<void> saveBookmark(Article article) async {
    if (_uid == null) return;

    final data = article.toJson();
    data['savedAt'] = FieldValue.serverTimestamp(); // add timestamp

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('bookmarks')
        .doc(article.id)
        .set(data);
  }

  // Remove Bookmark from Firestore
  Future<void> removeBookmark(String articleId) async {
    if (_uid == null) return;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('bookmarks')
        .doc(articleId)
        .delete();
  }

  // Check if bookmarked in Firestore
  Future<bool> isBookmarked(String articleId) async {
    if (_uid == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('bookmarks')
        .doc(articleId)
        .get();

    return doc.exists;
  }
}
