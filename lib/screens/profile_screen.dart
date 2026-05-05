import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/news_provider.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import '../services/opinion_service.dart';
import '../models/article.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _smartAlerts = true;
  bool _healthyDiet = false;
  String _userEmail = 'Loading...';
  int _readingStreak = 0;
  int _totalArticlesRead = 0;
  int _totalReadTimeMins = 0;
  int _mindChangedCount = 0;
  String _topMindChangedTopic = 'None';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchUser();
    _loadStreak();
  }

  Future<void> _fetchUser() async {
    final email = await AuthService().getCurrentUserEmail();
    final stats = await StatsService().getUserStats();
    final opinions = await OpinionService().getMindChangedStats();
    if (mounted) {
      setState(() {
        if (email != null) _userEmail = email;
        _totalArticlesRead = stats['totalArticlesRead'] ?? 0;
        _totalReadTimeMins = stats['totalReadTimeMins'] ?? 0;
        _mindChangedCount = opinions['totalChanged'] ?? 0;
        _topMindChangedTopic = opinions['topTopic'] ?? 'None';
      });
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _smartAlerts = prefs.getBool('smartAlerts') ?? true;
        _healthyDiet = prefs.getBool('healthyDiet') ?? false;
      });
    }
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('lastReadDate') ?? '';
    int streak = prefs.getInt('readingStreak') ?? 0;

    if (lastDate != today) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (lastDate == yesterday) {
        streak += 1;
      } else {
        streak = 1;
      }
      await prefs.setString('lastReadDate', today);
      await prefs.setInt('readingStreak', streak);
    }
    if (mounted) setState(() => _readingStreak = streak);
  }

  Future<void> _toggleAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smartAlerts', value);
    setState(() => _smartAlerts = value);
  }

  Future<void> _toggleDiet(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('healthyDiet', value);
    setState(() => _healthyDiet = value);
    if (value && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🥗 Healthy Diet enabled!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          // Calculate live sentiment stats
          int positive = 0, negative = 0, neutral = 0;
          for (Article a in provider.articles) {
            if (a.sentiment == 'Positive') positive++;
            else if (a.sentiment == 'Negative') negative++;
            else neutral++;
          }
          int total = provider.articles.length;
          double posPct = total > 0 ? (positive / total) * 100 : 0;
          double negPct = total > 0 ? (negative / total) * 100 : 0;
          double neuPct = total > 0 ? (neutral / total) * 100 : 0;

          // Determine mood
          String moodEmoji;
          String moodLabel;
          if (posPct > negPct && posPct > neuPct) {
            moodEmoji = '😊';
            moodLabel = 'Mostly Positive';
          } else if (negPct > posPct && negPct > neuPct) {
            moodEmoji = '😟';
            moodLabel = 'Heavy Negativity';
          } else {
            moodEmoji = '😐';
            moodLabel = 'Balanced Mix';
          }

          return CustomScrollView(
            slivers: [
              // Gradient Header
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white24,
                            child: Text(
                              _userEmail.isNotEmpty ? _userEmail[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_userEmail, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('🔥 $_readingStreak day streak', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: const Text('Profile', style: TextStyle(color: Colors.white)),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // News Diet Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your News Diet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('$moodEmoji $moodLabel', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (total > 0)
                              SizedBox(
                                height: 160,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 3,
                                          centerSpaceRadius: 35,
                                          sections: [
                                            PieChartSectionData(
                                              color: const Color(0xFF2ECC71), value: posPct,
                                              title: posPct > 5 ? '${posPct.toStringAsFixed(0)}%' : '',
                                              radius: 35, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                                            ),
                                            PieChartSectionData(
                                              color: const Color(0xFF95A5A6), value: neuPct,
                                              title: neuPct > 5 ? '${neuPct.toStringAsFixed(0)}%' : '',
                                              radius: 35, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                                            ),
                                            PieChartSectionData(
                                              color: const Color(0xFFE74C3C), value: negPct,
                                              title: negPct > 5 ? '${negPct.toStringAsFixed(0)}%' : '',
                                              radius: 35, titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _legendDot(const Color(0xFF2ECC71), 'Positive', positive),
                                        const SizedBox(height: 10),
                                        _legendDot(const Color(0xFF95A5A6), 'Neutral', neutral),
                                        const SizedBox(height: 10),
                                        _legendDot(const Color(0xFFE74C3C), 'Negative', negative),
                                        const SizedBox(height: 16),
                                        Text('$total total articles', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Read some news to see your diet!'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Smart Settings
                      const Text('Smart Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('🔔 Smart Alerts'),
                              subtitle: const Text('Notify only on major breaking news'),
                              value: _smartAlerts,
                              onChanged: _toggleAlerts,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            const Divider(height: 0, indent: 16, endIndent: 16),
                            SwitchListTile(
                              title: const Text('🥗 Healthy News Diet'),
                              subtitle: const Text('Reduce negative sentiment exposure'),
                              value: _healthyDiet,
                              onChanged: _toggleDiet,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Row
                      const Text('Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _statCard('📰', '$_totalArticlesRead', 'Articles\nRead', isDark),
                          const SizedBox(width: 12),
                          _statCard('⏱️', '$_totalReadTimeMins', 'Minutes\nRead', isDark),
                          const SizedBox(width: 12),
                          _statCard('🔥', '$_readingStreak', 'Day\nStreak', isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Mind Changed Feature
                      const Text('Mind Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.psychology, size: 40, color: Colors.blueAccent),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Persuasion Index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _mindChangedCount > 0 
                                      ? 'You changed your mind on $_mindChangedCount articles. You are most open-minded about $_topMindChangedTopic.'
                                      : 'You haven\'t changed your mind on any articles yet. Stay open!',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await AuthService().logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed('/');
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendDot(Color color, String label, int count) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text('$label ($count)', style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _statCard(String emoji, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
