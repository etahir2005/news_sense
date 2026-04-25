import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../models/article.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.articles.isEmpty) return const Center(child: Text("No articles available."));
          int pos = 0, neg = 0, neu = 0;
          Map<String, int> src = {};
          for (Article a in provider.articles) {
            if (a.sentiment == 'Positive') pos++;
            else if (a.sentiment == 'Negative') neg++;
            else neu++;
            src[a.sourceName] = (src[a.sourceName] ?? 0) + 1;
          }
          int total = provider.articles.length;
          double pp = (pos / total) * 100, np = (neg / total) * 100, nup = (neu / total) * 100;
          var top = (src.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sentiment Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Analyzing $total articles', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 24),
                  SizedBox(height: 200, child: Row(children: [
                    Expanded(child: PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 40, sections: [
                      PieChartSectionData(color: const Color(0xFF2ECC71), value: pp, title: pp > 5 ? '${pp.toStringAsFixed(0)}%' : '', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      PieChartSectionData(color: const Color(0xFF95A5A6), value: nup, title: nup > 5 ? '${nup.toStringAsFixed(0)}%' : '', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      PieChartSectionData(color: const Color(0xFFE74C3C), value: np, title: np > 5 ? '${np.toStringAsFixed(0)}%' : '', radius: 45, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                    ]))),
                    const SizedBox(width: 20),
                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _leg(const Color(0xFF2ECC71), 'Positive', pos),
                      const SizedBox(height: 12),
                      _leg(const Color(0xFF95A5A6), 'Neutral', neu),
                      const SizedBox(height: 12),
                      _leg(const Color(0xFFE74C3C), 'Negative', neg),
                    ]),
                  ])),
                ]),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Top News Sources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...top.map((e) {
                    double p = (e.value / total) * 100;
                    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${e.value} (${p.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: p / 100, minHeight: 8, backgroundColor: Colors.grey.withOpacity(0.15), color: const Color(0xFF667eea))),
                    ]));
                  }),
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          );
        },
      ),
    );
  }

  Widget _leg(Color c, String l, int n) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Text('$l ($n)', style: const TextStyle(fontSize: 13)),
  ]);
}
