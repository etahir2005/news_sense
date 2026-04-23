import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../models/article.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily News Mood', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.articles.isEmpty) {
            return const Center(child: Text("No articles available for analytics."));
          }

          int positive = 0;
          int negative = 0;
          int neutral = 0;

          for (Article a in provider.articles) {
            if (a.sentiment == 'Positive') positive++;
            else if (a.sentiment == 'Negative') negative++;
            else neutral++;
          }
          
          int total = provider.articles.length;
          double posPct = (positive / total) * 100;
          double negPct = (negative / total) * 100;
          double neuPct = (neutral / total) * 100;

          return SingleChildScrollView(
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
                Text(
                  'Analyzing \${provider.articles.length} breaking articles in your feed.',
                  style: const TextStyle(color: Colors.grey),
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
                          value: negPct,
                          title: negPct > 5 ? '\${negPct.toStringAsFixed(0)}%' : '',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.blueGrey,
                          value: neuPct,
                          title: neuPct > 5 ? '\${neuPct.toStringAsFixed(0)}%' : '',
                          radius: 50,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        PieChartSectionData(
                          color: Colors.green,
                          value: posPct,
                          title: posPct > 5 ? '\${posPct.toStringAsFixed(0)}%' : '',
                          radius: 60,
                          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildLegendRow('Positive Mentions', Colors.green, positive),
                const SizedBox(height: 8),
                _buildLegendRow('Neutral Updates', Colors.blueGrey, neutral),
                const SizedBox(height: 8),
                _buildLegendRow('Negative/Stressful', Colors.redAccent, negative),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 16, height: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
        Text('\$count articles', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
