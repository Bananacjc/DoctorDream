import 'package:flutter/material.dart';

import '../data/local/local_database.dart';
import '../data/models/article_recommendation.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.article});

  final ArticleRecommendation article;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final isSaved = await LocalDatabase.instance.isArticleSaved(widget.article);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await LocalDatabase.instance.removeArticle(widget.article);
    } else {
      await LocalDatabase.instance.saveArticle(widget.article);
    }
    if (mounted) {
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved ? 'Added to Calm Kit' : 'Removed from Calm Kit',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Article'),
        actions: [
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(
              _isSaved ? Icons.favorite : Icons.favorite_border,
              color: _isSaved ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF081944), // navy
              Color(0xFF0D2357), // slightly lighter navy
              Color(0xFF152C69), // even lighter
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.article.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: 'Article details',
                    onPressed: () => _showDetails(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.article.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7B9FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFFB7B9FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2357),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildContentBlocks(widget.article.content),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final summary = _cleanInlineMarkdown(widget.article.summary);
    final mood = widget.article.moodBenefit?.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2357),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Article details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (mood != null && mood.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mood,
                    style: const TextStyle(
                      color: Color(0xFFB7B9FF),
                      fontSize: 14,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    summary,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildContentBlocks(String rawContent) {
    final lines = rawContent.split('\n');
    final blocks = <Widget>[];
    var isFirst = true;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      if (line.startsWith(RegExp(r'^#{1,6}\s'))) {
        final heading = line.replaceFirst(RegExp(r'^#{1,6}\s*'), '').trim();
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 16),
            child: Text(
              _cleanInlineMarkdown(heading),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        isFirst = false;
        continue;
      }

      if (line.startsWith(RegExp(r'^(\*|-)\s+'))) {
        final bullet = _cleanInlineMarkdown(
          line.replaceFirst(RegExp(r'^(\*|-)\s+'), ''),
        );
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    '•',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
        isFirst = false;
        continue;
      }

      if (line.startsWith(RegExp(r'^\d+\.\s+'))) {
        final numbered = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: isFirst ? 0 : 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '•',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cleanInlineMarkdown(numbered),
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        );
        isFirst = false;
        continue;
      }

      blocks.add(
        Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 12),
          child: Text(
            _cleanInlineMarkdown(line),
            style: const TextStyle(color: Colors.white, height: 1.6),
          ),
        ),
      );
      isFirst = false;
    }

    if (blocks.isEmpty) {
      blocks.add(
        const Text(
          'No content available.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return blocks;
  }

  String _cleanInlineMarkdown(String text) {
    var result = text;

    result = result.replaceAllMapped(
      RegExp(r'\[(.*?)\]\((.*?)\)'),
      (match) => match.group(1) ?? '',
    );
    result = result.replaceAll('**', '');
    result = result.replaceAll('*', '');
    result = result.replaceAll('`', '');

    return result.trim();
  }
}
