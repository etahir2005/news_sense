import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/article.dart';

class DigestScreen extends StatefulWidget {
  const DigestScreen({super.key});

  @override
  State<DigestScreen> createState() => _DigestScreenState();
}

class _DigestScreenState extends State<DigestScreen> {
  final NewsService _service = NewsService();
  bool _isLoading = true;
  List<Article> _localTop = [];
  List<Article> _globalTop = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDigest();
  }

  Future<void> _fetchDigest() async {
    try {
      // Fetch top 3 Local
      final localRes = await _service.fetchLiveNews(category: 'top', isGlobal: false);
      // Fetch top 3 Global
      final globalRes = await _service.fetchLiveNews(category: 'top', isGlobal: true);

      if (mounted) {
        setState(() {
          _localTop = (localRes['articles'] as List<Article>).take(3).toList();
          _globalTop = (globalRes['articles'] as List<Article>).take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFDFDFD),
      appBar: AppBar(
        title: const Text('Morning Digest', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text("Error generating digest: $_error"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Daily Executive Summary.',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distraction-free. Just the facts.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('National Focus 🇵🇰'),
                  ..._localTop.map((a) => _buildDigestItem(a, isDark)),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('Global Overview 🌐'),
                  ..._globalTop.map((a) => _buildDigestItem(a, isDark)),
                  
                  const SizedBox(height: 40),
                  const Center(child: Icon(Icons.spa, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Center(child: Text('You are all caught up.', style: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF667eea)),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 2),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDigestItem(Article article, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            article.summary,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                article.sourceName.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.grey[500])),
              const SizedBox(width: 8),
              Text(
                article.credibilityScore > 80 ? 'Highly Objective' : (article.credibilityScore > 50 ? 'Slight Bias' : 'Sensationalized'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: article.credibilityScore > 80 ? const Color(0xFF2ECC71) : (article.credibilityScore > 50 ? Colors.orange : const Color(0xFFE74C3C)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
