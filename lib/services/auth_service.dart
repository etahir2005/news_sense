import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Signs up a user via Firebase Auth and creates Firestore profile
  Future<bool> signUp(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      print("SignUp Error: $e");
      return false;
    }
  }

  // Logs a user in via Firebase
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Login Error: $e");
      return false;
    }
  }

  // Logs out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Checks if someone is currently logged in (returns UID)
  Future<String?> getCurrentUser() async {
    return _auth.currentUser?.uid;
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    return _auth.currentUser?.email;
  }
}
