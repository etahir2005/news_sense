import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          const Center(child: Text('Jane Doe', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          const Center(child: Text('jane.doe@example.com', style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 32),
          const Text('Smart Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Enable Smart Alerts'),
            subtitle: const Text('Notify only on major highly positive/negative news'),
            value: true,
            onChanged: (v) {},
            secondary: const Icon(Icons.notifications_active),
          ),
          SwitchListTile(
            title: const Text('Healthy News Diet'),
            subtitle: const Text('Limit exposure to negative sentiment articles'),
            value: true,
            onChanged: (v) {},
            secondary: const Icon(Icons.spa),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Submit Feedback'),
            onTap: () {
              // Usually navigates to feedback screen
            },
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          )
        ],
      ),
    );
  }
}
