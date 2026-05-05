import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OpinionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> savePreReadOpinion(String articleId, String topic, String opinion) async {
    if (_uid == null) return;
    final docRef = _firestore.collection('users').doc(_uid).collection('opinions').doc(articleId);
    
    await docRef.set({
      'topic': topic,
      'preRead': opinion,
      'postRead': null, // To be filled later
      'changedMind': false,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePostReadOpinion(String articleId, String topic, String opinion) async {
    if (_uid == null) return;
    final docRef = _firestore.collection('users').doc(_uid).collection('opinions').doc(articleId);
    
    final snapshot = await docRef.get();
    bool changedMind = false;
    if (snapshot.exists) {
      final data = snapshot.data()!;
      if (data['preRead'] != null && data['preRead'] != opinion) {
        changedMind = true;
      }
    }

    await docRef.set({
      'topic': topic,
      'postRead': opinion,
      'changedMind': changedMind,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getMindChangedStats() async {
    if (_uid == null) return {'totalChanged': 0, 'topTopic': 'None'};
    
    final snapshot = await _firestore.collection('users').doc(_uid).collection('opinions').where('changedMind', isEqualTo: true).get();
    
    int totalChanged = snapshot.docs.length;
    Map<String, int> topicCounts = {};
    
    for (var doc in snapshot.docs) {
      String topic = doc.data()['topic'] ?? 'General';
      topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
    }

    String topTopic = 'None';
    int maxCount = 0;
    topicCounts.forEach((topic, count) {
      if (count > maxCount) {
        maxCount = count;
        topTopic = topic;
      }
    });

    return {
      'totalChanged': totalChanged,
      'topTopic': topTopic,
    };
  }
}
