import 'package:flutter/material.dart';
import '../services/news_service.dart';
import '../models/article.dart';
import '../widgets/news_card.dart';

class GlobalFrontPagesScreen extends StatelessWidget {
  GlobalFrontPagesScreen({super.key});

  final List<Map<String, String>> _countries = [
    {'code': 'pk', 'name': 'Pakistan', 'flag': '🇵🇰', 'color': '0xFF2ECC71'},
    {'code': 'us', 'name': 'United States', 'flag': '🇺🇸', 'color': '0xFF3498DB'},
    {'code': 'gb', 'name': 'United Kingdom', 'flag': '🇬🇧', 'color': '0xFF9B59B6'},
    {'code': 'in', 'name': 'India', 'flag': '🇮🇳', 'color': '0xFFE67E22'},
    {'code': 'cn', 'name': 'China', 'flag': '🇨🇳', 'color': '0xFFE74C3C'},
    {'code': 'de', 'name': 'Germany', 'flag': '🇩🇪', 'color': '0xFF1ABC9C'},
    {'code': 'fr', 'name': 'France', 'flag': '🇫🇷', 'color': '0xFF667eea'},
    {'code': 'au', 'name': 'Australia', 'flag': '🇦🇺', 'color': '0xFFF39C12'},
    {'code': 'ca', 'name': 'Canada', 'flag': '🇨🇦', 'color': '0xFFE74C3C'},
    {'code': 'jp', 'name': 'Japan', 'flag': '🇯🇵', 'color': '0xFFFF6B81'},
    {'code': 'br', 'name': 'Brazil', 'flag': '🇧🇷', 'color': '0xFF2ECC71'},
    {'code': 'za', 'name': 'South Africa', 'flag': '🇿🇦', 'color': '0xFF9B59B6'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            floating: true,
            snap: true,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌍 World Desk', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Front-page headlines from ${_countries.length} countries',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CountryCard(country: _countries[index]),
                childCount: _countries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatefulWidget {
  final Map<String, String> country;
  const _CountryCard({required this.country});

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> with SingleTickerProviderStateMixin {
  final NewsService _service = NewsService();
  Article? _topArticle;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fetchTopHeadline();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopHeadline() async {
    try {
      // Pass isGlobal: true so no Pakistan query leaks in
      // Also pass the country name as the query to strictly filter news about this country
      final res = await _service.fetchLiveNews(
        country: widget.country['code'],
        query: widget.country['name']!,
        category: 'top',
        isGlobal: true,
      );
      final articles = res['articles'] as List<Article>;
      if (mounted) {
        setState(() {
          if (articles.isNotEmpty) _topArticle = articles.first;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Color(int.parse(widget.country['color']!));

    return FadeTransition(
      opacity: CurvedAnimation(parent: _animController, curve: Curves.easeOut),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => CountryHeadlinesScreen(
                countryName: widget.country['name']!,
                countryCode: widget.country['code']!,
                flag: widget.country['flag']!,
              ),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: child,
                );
              },
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Flag + Country Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor.withOpacity(0.15), accentColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Text(widget.country['flag']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.country['name']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_topArticle != null)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _topArticle!.sentiment == 'Positive'
                                    ? const Color(0xFF2ECC71).withOpacity(0.2)
                                    : _topArticle!.sentiment == 'Negative'
                                        ? const Color(0xFFE74C3C).withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _topArticle!.sentiment == 'Positive' ? '😊 Positive' : _topArticle!.sentiment == 'Negative' ? '😟 Negative' : '😐 Neutral',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                                  color: _topArticle!.sentiment == 'Positive' ? const Color(0xFF2ECC71)
                                      : _topArticle!.sentiment == 'Negative' ? const Color(0xFFE74C3C)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isLoading
                    ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: accentColor))
                    : _error != null || _topArticle == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_off, color: Colors.grey[400], size: 28),
                              const SizedBox(height: 6),
                              Text('No headlines', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _topArticle!.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _topArticle!.sourceName.toUpperCase(),
                                    style: TextStyle(fontSize: 9, color: accentColor, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sub-screen: Top 5 headlines for a country
class CountryHeadlinesScreen extends StatefulWidget {
  final String countryName;
  final String countryCode;
  final String flag;

  const CountryHeadlinesScreen({super.key, required this.countryName, required this.countryCode, required this.flag});

  @override
  State<CountryHeadlinesScreen> createState() => _CountryHeadlinesScreenState();
}

class _CountryHeadlinesScreenState extends State<CountryHeadlinesScreen> {
  final NewsService _service = NewsService();
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final res = await _service.fetchLiveNews(
        country: widget.countryCode,
        query: widget.countryName,
        category: 'top',
        isGlobal: true,
      );
      if (mounted) {
        setState(() {
          _articles = (res['articles'] as List<Article>).take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.flag} ${widget.countryName}'),
        centerTitle: true,
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
                    Text('Could not load news for ${widget.countryName}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () { setState(() { _isLoading = true; _error = null; }); _loadNews(); },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _articles.isEmpty
              ? Center(child: Text('No English headlines available for ${widget.countryName}'))
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _articles.length,
                    itemBuilder: (context, index) => NewsCard(article: _articles[index]),
                  ),
                ),
    );
  }
}
