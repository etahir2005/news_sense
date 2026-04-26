import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Signs up a user by saving their credentials locally
  Future<bool> signUp(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already exists
    if (prefs.containsKey('user_$email')) {
      return false; // User exists
    }

    // Save basic auth locally
    await prefs.setString('user_$email', password);
    await prefs.setString('currentUser', email);
    return true;
  }

  // Logs a user in by checking saved credentials
  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    String? savedPassword = prefs.getString('user_$email');
    if (savedPassword != null && savedPassword == password) {
      await prefs.setString('currentUser', email);
      return true;
    }
    return false;
  }

  // Logs out
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');
  }

  // Checks if someone is currently logged in
  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentUser');
  }
}
