import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _smartAlerts = true;
  bool _healthyDiet = false;
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final email = await AuthService().getCurrentUser();
    if (email != null && mounted) {
      setState(() {
        _userEmail = email;
      });
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _smartAlerts = prefs.getBool('smartAlerts') ?? true;
      _healthyDiet = prefs.getBool('healthyDiet') ?? false;
    });
  }

  Future<void> _toggleAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smartAlerts', value);
    setState(() {
      _smartAlerts = value;
    });
  }

  Future<void> _toggleDiet(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('healthyDiet', value);
    setState(() {
      _healthyDiet = value;
    });
    
    if (value && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Healthy Diet enabled. Negative news will be minimized.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Center(child: Text('NewsSense Insider', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          Center(child: Text(_userEmail, style: const TextStyle(color: Colors.grey))),
          const SizedBox(height: 32),
          const Text('Smart Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Enable Smart Alerts'),
            subtitle: const Text('Notify only on major highly positive/negative news'),
            value: _smartAlerts,
            onChanged: _toggleAlerts,
            secondary: const Icon(Icons.notifications_active),
          ),
          SwitchListTile(
            title: const Text('Healthy News Diet'),
            subtitle: const Text('Limit exposure to negative sentiment articles'),
            value: _healthyDiet,
            onChanged: _toggleDiet,
            secondary: const Icon(Icons.spa),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Submit Feedback'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening feedback form...')));
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                 Navigator.of(context).pushReplacementNamed('/');
              }
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }
}
