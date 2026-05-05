import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> logArticleRead(String articleId, String topic, int wordCount) async {
    if (_uid == null) return;
    int readTimeMins = (wordCount / 200).ceil();
    if (readTimeMins < 1) readTimeMins = 1;

    final docRef = _firestore.collection('users').doc(_uid).collection('history').doc();
    await docRef.set({
      'articleId': articleId,
      'topic': topic,
      'readTimeMins': readTimeMins,
      'readAt': FieldValue.serverTimestamp(),
    });

    // Update aggregate stats
    final userDoc = _firestore.collection('users').doc(_uid);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) {
          transaction.set(userDoc, {
            'totalArticlesRead': 1,
            'totalReadTimeMins': readTimeMins,
          });
        } else {
          int totalRead = (snapshot.data()?['totalArticlesRead'] ?? 0) as int;
          int totalTime = (snapshot.data()?['totalReadTimeMins'] ?? 0) as int;
          
          transaction.update(userDoc, {
            'totalArticlesRead': totalRead + 1,
            'totalReadTimeMins': totalTime + readTimeMins,
          });
        }
      });
    } catch (e) {
      print('Stats transaction failed: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    if (_uid == null) return {};
    final snapshot = await _firestore.collection('users').doc(_uid).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return {};
  }
}
