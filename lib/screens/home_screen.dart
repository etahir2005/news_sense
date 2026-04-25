import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _moodFilter = 'All'; // Unique: Mood-based filtering

  final List<String> _categories = ['top', 'politics', 'business', 'technology', 'sports', 'entertainment'];
  final List<String> _moods = ['All', 'Positive', 'Neutral', 'Negative'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<NewsProvider>().fetchMoreNews();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              snap: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const SafeArea(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NewsSense', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          Text('Smart Insights · Pakistan 🇵🇰', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Pakistan news...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            context.read<NewsProvider>().setSearch('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) => setState(() {}),
                onSubmitted: (val) {
                  context.read<NewsProvider>().setSearch(val);
                },
              ),
            ),

            // Category Chips
            Consumer<NewsProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = provider.currentCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            cat == 'top' ? '🔥 Top' : cat[0].toUpperCase() + cat.substring(1),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : null,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF667eea),
                          onSelected: (selected) {
                            if (selected) {
                              _searchController.clear();
                              provider.setCategory(cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Mood Filter — UNIQUE FEATURE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('Mood:', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  ..._moods.map((mood) {
                    final isActive = _moodFilter == mood;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _moodFilter = mood),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF667eea).withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? const Color(0xFF667eea) : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            mood == 'All' ? '🌐 All' : mood == 'Positive' ? '😊' : mood == 'Negative' ? '😟' : '😐',
                            style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // News Feed
            Expanded(
              child: Consumer<NewsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return _buildShimmerLoader();
                  }

                  if (provider.errorMessage != null && provider.articles.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Could not connect to news service.', style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            Text('Check your internet or try again.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => provider.fetchInitialNews(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Apply mood filter
                  final filtered = _moodFilter == 'All'
                      ? provider.articles
                      : provider.articles.where((a) => a.sentiment == _moodFilter).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🤷', style: TextStyle(fontSize: 50)),
                          const SizedBox(height: 12),
                          Text(
                            _moodFilter != 'All' ? 'No $_moodFilter news found.' : 'No articles found.',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchInitialNews(),
                    color: const Color(0xFF667eea),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length + (provider.hasMore && _moodFilter == 'All' ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return NewsCard(article: filtered[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  color: Colors.grey.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, color: Colors.grey.withOpacity(0.15)),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 200, color: Colors.grey.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    Container(height: 10, width: 100, color: Colors.grey.withOpacity(0.1)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
