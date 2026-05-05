import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../services/tts_service.dart';
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

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  Future<void> _fetchDigest() async {
    try {
      final localRes = await _service.fetchLiveNews(category: 'top', isGlobal: false);
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

  void _playBriefing() {
    final tts = TtsService();
    if (tts.currentlyPlaying.value == '__briefing__') {
      tts.stop();
      return;
    }
    final headlines = [
      ..._localTop.map((a) => '${a.title}. ${a.summary}'),
      ..._globalTop.map((a) => '${a.title}. ${a.summary}'),
    ];
    tts.speakBriefing(headlines);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; _error = null; });
              _fetchDigest();
            },
          ),
        ],
      ),
      // 🎧 Play Briefing FAB
      floatingActionButton: _isLoading || _error != null
          ? null
          : ValueListenableBuilder<String?>(
              valueListenable: TtsService().currentlyPlaying,
              builder: (context, playingId, _) {
                final isBriefing = playingId == '__briefing__';
                return FloatingActionButton.extended(
                  onPressed: _playBriefing,
                  backgroundColor: isBriefing ? Colors.redAccent : const Color(0xFF667eea),
                  icon: Icon(isBriefing ? Icons.stop : Icons.headphones, color: Colors.white),
                  label: Text(
                    isBriefing ? 'Stop Briefing' : '🎙️ Play Briefing',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 50, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Could not load digest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () { setState(() { _isLoading = true; _error = null; }); _fetchDigest(); },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667eea), foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDigest,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Daily\nExecutive Summary.',
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
                      'Tap 🎙️ to listen hands-free.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildSectionHeader('Local Headlines'),
                    ..._localTop.asMap().entries.map((e) => _buildDigestItem(e.value, isDark, e.key + 1)),
                    
                    const SizedBox(height: 40),
                    
                    _buildSectionHeader('Global Headlines'),
                    ..._globalTop.asMap().entries.map((e) => _buildDigestItem(e.value, isDark, e.key + 1)),
                    
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF667eea), size: 18),
                            SizedBox(width: 8),
                            Text('You are all caught up', style: TextStyle(color: Color(0xFF667eea), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80), // space for FAB
                  ],
                ),
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

  Widget _buildDigestItem(Article article, bool isDark, int number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('$number', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667eea))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  article.summary,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.sourceName.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (article.credibilityScore > 80 ? const Color(0xFF2ECC71) : (article.credibilityScore > 50 ? Colors.orange : const Color(0xFFE74C3C))).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.credibilityScore > 80 ? 'Objective' : (article.credibilityScore > 50 ? 'Slight Bias' : 'Clickbait'),
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: article.credibilityScore > 80 ? const Color(0xFF2ECC71) : (article.credibilityScore > 50 ? Colors.orange : const Color(0xFFE74C3C)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Mini listen button per story
                    ValueListenableBuilder<String?>(
                      valueListenable: TtsService().currentlyPlaying,
                      builder: (context, playingId, _) {
                        final isPlaying = playingId == article.id;
                        return GestureDetector(
                          onTap: () => TtsService().speak(
                            '${article.title}. ${article.summary}',
                            article.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isPlaying ? const Color(0xFF667eea) : Colors.grey).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isPlaying ? Icons.stop : Icons.headphones,
                              size: 16,
                              color: isPlaying ? const Color(0xFF667eea) : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
