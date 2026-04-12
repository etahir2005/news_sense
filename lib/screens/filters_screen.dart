import 'package:flutter/material.dart';

class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filters & Perspectives')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(label: const Text('Business'), selected: true, onSelected: (v) {}),
              FilterChip(label: const Text('Technology'), selected: true, onSelected: (v) {}),
              FilterChip(label: const Text('Politics'), selected: false, onSelected: (v) {}),
              FilterChip(label: const Text('Health'), selected: false, onSelected: (v) {}),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Perspective Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Show Multiple Viewpoints'),
            subtitle: const Text('Reduce bias by showing global & local angles'),
            value: true,
            onChanged: (v) {},
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          )
        ],
      ),
    );
  }
}
