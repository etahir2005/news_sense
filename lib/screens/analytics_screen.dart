import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily News Mood', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your News Diet Today',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A summary of the sentiment in your active feed.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: 30,
                      title: '30%',
                      radius: 50,
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.blueGrey,
                      value: 20,
                      title: '20%',
                      radius: 50,
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 50,
                      title: '50%',
                      radius: 60,
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildLegendRow('Positive Mentions', Colors.green),
            const SizedBox(height: 8),
            _buildLegendRow('Neutral Updates', Colors.blueGrey),
            const SizedBox(height: 8),
            _buildLegendRow('Negative/Stressful', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
