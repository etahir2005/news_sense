import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../services/bookmarks_service.dart';
import '../services/stats_service.dart';
import '../services/opinion_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';
import '../screens/article_webview_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsCard extends StatefulWidget {
  final Article article;

  const NewsCard({super.key, required this.article});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  bool _isInsightExpanded = false;
  bool _showUrdu = false;
  bool _isTranslating = false;
  String? _urduText;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedStatus() async {
    bool saved = await BookmarksService().isBookmarked(widget.article.id);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isSaved) {
      await BookmarksService().removeBookmark(widget.article.id);
    } else {
      await BookmarksService().saveBookmark(widget.article);
    }
    setState(() => _isSaved = !_isSaved);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSaved ? '📌 Saved to Bookmarks!' : 'Removed from Bookmarks.'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Color _getSentimentColor(String sentiment) {
    if (sentiment == 'Positive') return const Color(0xFF2ECC71);
    if (sentiment == 'Negative') return const Color(0xFFE74C3C);
    return const Color(0xFF95A5A6);
  }

  IconData _getSentimentIcon(String sentiment) {
    if (sentiment == 'Positive') return Icons.trending_up;
    if (sentiment == 'Negative') return Icons.trending_down;
    return Icons.trending_flat;
  }

  bool _isBreaking() {
    return DateTime.now().difference(widget.article.publishedAt).inHours < 24;
  }

  String _breakingLabel() {
    final hours = DateTime.now().difference(widget.article.publishedAt).inHours;
    if (hours < 4) return 'BREAKING';
    if (hours < 12) return 'JUST IN';
    return 'LATEST';
  }

  Future<void> _toggleUrdu() async {
    if (_showUrdu) {
      setState(() => _showUrdu = false);
      return;
    }
    if (_urduText != null) {
      setState(() => _showUrdu = true);
      return;
    }
    setState(() => _isTranslating = true);
    final translated = await TranslationService.translateToUrdu(widget.article.summary);
    if (mounted) {
      setState(() {
        _urduText = translated;
        _showUrdu = true;
        _isTranslating = false;
      });
    }
  }

  void _showOpinionDialog(bool isPostRead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Icon(isPostRead ? Icons.psychology : Icons.question_mark, size: 40, color: const Color(0xFF667eea)),
              const SizedBox(height: 12),
              Text(
                isPostRead ? 'Did reading this change your mind?' : 'What\'s your gut feeling about this?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.article.title,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _opinionButton('👍', 'Agree', const Color(0xFF2ECC71), isPostRead),
                  _opinionButton('🤷', 'Neutral', const Color(0xFF95A5A6), isPostRead),
                  _opinionButton('👎', 'Disagree', const Color(0xFFE74C3C), isPostRead),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _opinionButton(String emoji, String value, Color color, bool isPostRead) {
    return InkWell(
      onTap: () {
        if (isPostRead) {
          OpinionService().savePostReadOpinion(widget.article.id, widget.article.sourceName, value);
        } else {
          OpinionService().savePreReadOpinion(widget.article.id, widget.article.sourceName, value);
        }
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$emoji Opinion recorded!'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _openArticle() async {
    if (widget.article.url.isNotEmpty) {
      StatsService().logArticleRead(widget.article.id, widget.article.sourceName, widget.article.summary.split(' ').length);
      if (kIsWeb) {
        final uri = Uri.parse(widget.article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        await Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ArticleWebViewScreen(
              url: widget.article.url,
              title: widget.article.sourceName,
            ),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              );
            },
          ),
        );
        if (mounted) {
          _showOpinionDialog(true);
        }
      }
    }
  }

  void _shareArticle() {
    Share.share(
      '📰 ${widget.article.title}\n\n'
      '🤖 AI Sentiment: ${widget.article.sentiment}\n'
      '📊 Credibility: ${widget.article.credibilityScore}/100\n\n'
      '🔗 ${widget.article.url}\n\n'
      'Shared via NewsSense — Smart News, Less Noise.',
    );
  }

  String _getReadingTime() {
    int wordCount = widget.article.summary.split(' ').length;
    int minutes = (wordCount / 200).ceil();
    if (minutes < 1) minutes = 1;
    return '$minutes min read';
  }

  String _getTimeSincePublished() {
    final diff = DateTime.now().difference(widget.article.publishedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBreaking = _isBreaking();

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _openArticle,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image with gradient overlay
              Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withOpacity(0.2), Colors.deepPurple.withOpacity(0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: kIsWeb
                        ? Image.network(
                            widget.article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            headers: const {},
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF667eea).withOpacity(0.3), const Color(0xFF764ba2).withOpacity(0.3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.newspaper, size: 48, color: Colors.white70),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.article.sourceName,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.network(
                            widget.article.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF667eea).withOpacity(0.3), const Color(0xFF764ba2).withOpacity(0.3)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.newspaper, size: 60, color: Colors.white70),
                                ),
                              );
                            },
                          ),
                  ),
                  // Gradient overlay at bottom of image
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? const Color(0xFF1E1E2E) : Colors.white).withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Source badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.article.sourceName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                  // Time badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(_getTimeSincePublished(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  // BREAKING badge
                  if (isBreaking)
                    Positioned(
                      top: 12, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(_breakingLabel(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sentiment + Reading Time Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _getSentimentColor(widget.article.sentiment).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getSentimentIcon(widget.article.sentiment), size: 14, color: _getSentimentColor(widget.article.sentiment)),
                              const SizedBox(width: 4),
                              Text(
                                widget.article.sentiment,
                                style: TextStyle(color: _getSentimentColor(widget.article.sentiment), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book, size: 14, color: Colors.blueAccent),
                              const SizedBox(width: 4),
                              Text(_getReadingTime(), style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      widget.article.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // AI Insight — tappable, expands inline
                    GestureDetector(
                      onTap: () {
                        setState(() => _isInsightExpanded = !_isInsightExpanded);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.blueAccent).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 16, color: Colors.blueAccent),
                                const SizedBox(width: 6),
                                Text('AI Insight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent.shade700)),
                                const Spacer(),
                                // 🇵🇰 Urdu Translation Toggle
                                GestureDetector(
                                  onTap: () {
                                    _toggleUrdu();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _showUrdu ? const Color(0xFF2ECC71).withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _showUrdu ? const Color(0xFF2ECC71).withOpacity(0.4) : Colors.transparent),
                                    ),
                                    child: _isTranslating
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                        : Text(
                                            _showUrdu ? 'English' : '🇵🇰 اردو',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _showUrdu ? const Color(0xFF2ECC71) : Colors.grey[600]),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _isInsightExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 18, color: Colors.blueAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedCrossFade(
                              firstChild: Text(
                                _showUrdu ? (_urduText ?? widget.article.summary) : widget.article.summary,
                                style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              secondChild: Text(
                                _showUrdu ? (_urduText ?? widget.article.summary) : widget.article.summary,
                                style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700]),
                                textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                              ),
                              crossFadeState: _isInsightExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Credibility Radar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Credibility Radar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                            Text(
                              widget.article.credibilityScore > 80 ? 'Highly Objective' 
                              : widget.article.credibilityScore > 50 ? 'Slight Bias' 
                              : 'Possible Clickbait',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold, 
                                color: widget.article.credibilityScore > 80 ? const Color(0xFF2ECC71)
                                  : widget.article.credibilityScore > 50 ? Colors.orange
                                  : const Color(0xFFE74C3C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: widget.article.credibilityScore / 100),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: Colors.grey.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.article.credibilityScore > 80 ? const Color(0xFF2ECC71)
                                  : widget.article.credibilityScore > 50 ? Colors.orange
                                  : const Color(0xFFE74C3C),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openArticle,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('Read Full', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 🎧 Listen Button — TTS
                        ValueListenableBuilder<String?>(
                          valueListenable: TtsService().currentlyPlaying,
                          builder: (context, playingId, _) {
                            final isPlaying = playingId == widget.article.id;
                            return IconButton(
                              icon: Icon(isPlaying ? Icons.stop_circle : Icons.headphones, size: 20),
                              onPressed: () => TtsService().speak(
                                '${widget.article.title}. ${widget.article.summary}',
                                widget.article.id,
                              ),
                              color: isPlaying ? const Color(0xFF667eea) : Colors.grey,
                              tooltip: isPlaying ? 'Stop' : 'Listen',
                              style: IconButton.styleFrom(
                                backgroundColor: (isPlaying ? const Color(0xFF667eea) : Colors.grey).withOpacity(0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              _isSaved ? Icons.bookmark : Icons.bookmark_border,
                              key: ValueKey(_isSaved),
                              size: 20,
                            ),
                          ),
                          onPressed: _toggleBookmark,
                          color: _isSaved ? Colors.blueAccent : Colors.grey,
                          style: IconButton.styleFrom(
                            backgroundColor: (_isSaved ? Colors.blueAccent : Colors.grey).withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.psychology_outlined, size: 20),
                          onPressed: () => _showOpinionDialog(false),
                          tooltip: 'Share your opinion',
                          color: Colors.grey,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, size: 20),
                          onPressed: _shareArticle,
                          color: Colors.grey,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
