import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/local/local_database.dart';
import '../data/models/music_track.dart';
import '../data/models/video_track.dart';
import '../data/models/article_recommendation.dart';
import 'song_player_screen.dart';
import 'video_player_screen.dart';
import 'article_screen.dart';

class CalmKitScreen extends StatefulWidget {
  const CalmKitScreen({super.key});

  @override
  State<CalmKitScreen> createState() => _CalmKitScreenState();
}

class _SavedItem {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'music', 'video', 'article'
  final dynamic originalItem;
  final String? thumbnailUrl;
  final DateTime savedAt;

  _SavedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.originalItem,
    this.thumbnailUrl,
    required this.savedAt,
  });
}

enum _FilterType { all, music, video, article }
enum _SortOption { dateNewest, dateOldest, category }

class _CalmKitScreenState extends State<CalmKitScreen> {
  List<_SavedItem> _allItems = [];
  List<_SavedItem> _filteredItems = [];
  bool _isLoading = true;
  _FilterType _selectedFilter = _FilterType.all;
  _SortOption _selectedSort = _SortOption.dateNewest;

  @override
  void initState() {
    super.initState();
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    try {
      final music = await LocalDatabase.instance.fetchSavedMusic();
      final videos = await LocalDatabase.instance.fetchSavedVideos();
      final articles = await LocalDatabase.instance.fetchSavedArticles();

      final items = <_SavedItem>[];

      for (var item in music) {
        items.add(_SavedItem(
          id: 'music_${item.title}',
          title: item.title,
          subtitle: item.artist,
          type: 'music',
          originalItem: item,
          thumbnailUrl: item.thumbnailUrl,
          savedAt: item.savedAt ?? DateTime.now(), // Fallback if null, though DB should provide it
        ));
      }

      for (var item in videos) {
        items.add(_SavedItem(
          id: 'video_${item.title}',
          title: item.title,
          subtitle: item.channel ?? 'YouTube',
          type: 'video',
          originalItem: item,
          thumbnailUrl: item.thumbnailUrl,
          savedAt: item.savedAt ?? DateTime.now(),
        ));
      }

      for (var item in articles) {
        items.add(_SavedItem(
          id: 'article_${item.title}',
          title: item.title,
          subtitle: 'Article',
          type: 'article',
          originalItem: item,
          savedAt: item.savedAt ?? DateTime.now(),
        ));
      }

      if (mounted) {
        setState(() {
          _allItems = items;
          _applyFilterAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saved items: $e')),
        );
      }
    }
  }

  void _applyFilterAndSort() {
    // 1. Filter
    List<_SavedItem> temp;
    if (_selectedFilter == _FilterType.all) {
      temp = List.from(_allItems);
    } else {
      final typeString = _selectedFilter.name;
      temp = _allItems.where((item) => item.type == typeString).toList();
    }

    // 2. Sort
    switch (_selectedSort) {
      case _SortOption.dateNewest:
        temp.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
      case _SortOption.dateOldest:
        temp.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        break;
      case _SortOption.category:
        // Sort by type first (Music -> Video -> Article), then date descending
        temp.sort((a, b) {
          int typeCompare = a.type.compareTo(b.type);
          if (typeCompare != 0) return typeCompare;
          return b.savedAt.compareTo(a.savedAt);
        });
        break;
    }

    _filteredItems = temp;
  }

  void _onFilterChanged(_FilterType type) {
    setState(() {
      _selectedFilter = type;
      _applyFilterAndSort();
    });
  }

  void _onSortChanged(_SortOption sort) {
    setState(() {
      _selectedSort = sort;
      _applyFilterAndSort();
    });
  }

  Future<void> _removeItem(int index) async {
    final item = _filteredItems[index];
    try {
      if (item.type == 'music') {
        await LocalDatabase.instance.removeMusic(item.originalItem as MusicTrack);
      } else if (item.type == 'video') {
        await LocalDatabase.instance.removeVideo(item.originalItem as VideoTrack);
      } else if (item.type == 'article') {
        await LocalDatabase.instance.removeArticle(item.originalItem as ArticleRecommendation);
      }

      setState(() {
        _allItems.removeWhere((element) => element.id == item.id);
        _applyFilterAndSort();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.title} removed'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                 // To implement Undo, we'd need to re-save. 
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  void _openItem(_SavedItem item) {
    if (item.type == 'music') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SongPlayerScreen(track: item.originalItem as MusicTrack),
        ),
      ).then((_) => _loadSavedItems());
    } else if (item.type == 'video') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(track: item.originalItem as VideoTrack),
        ),
      ).then((_) => _loadSavedItems());
    } else if (item.type == 'article') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArticleScreen(article: item.originalItem as ArticleRecommendation),
        ),
      ).then((_) => _loadSavedItems());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Calm Kit'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onSelected: _onSortChanged,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortOption.dateNewest,
                child: Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Newest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _SortOption.dateOldest,
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Oldest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _SortOption.category,
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('By Category'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1F44), Color(0xFF122A5C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedFilter == _FilterType.all,
                        onTap: () => _onFilterChanged(_FilterType.all),
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Music',
                        isSelected: _selectedFilter == _FilterType.music,
                        onTap: () => _onFilterChanged(_FilterType.music),
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Video',
                        isSelected: _selectedFilter == _FilterType.video,
                        onTap: () => _onFilterChanged(_FilterType.video),
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Articles',
                        isSelected: _selectedFilter == _FilterType.article,
                        onTap: () => _onFilterChanged(_FilterType.article),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _filteredItems.isEmpty
                        ? _EmptyState(filter: _selectedFilter)
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filteredItems.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65, // Optimized aspect ratio for card layout
                            ),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: const Color(0xFF0D2357),
                                        title: Text("Confirm", style: GoogleFonts.robotoFlex(color: Colors.white)),
                                        content: Text("Remove this item from your Calm Kit?", style: GoogleFonts.robotoFlex(color: Colors.white70)),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: Text("Cancel", style: GoogleFonts.robotoFlex(color: Colors.white54)),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: Text("Remove", style: GoogleFonts.robotoFlex(color: Colors.redAccent)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (_) => _removeItem(index),
                                background: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                child: _CalmResourceCard(
                                  item: item,
                                  onTap: () => _openItem(item),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB7B9FF) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFB7B9FF) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.robotoFlex(
              color: isSelected ? const Color(0xFF081944) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final _FilterType filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (filter) {
      case _FilterType.music:
        message = 'No saved music yet.\nFind some tunes to relax!';
        icon = Icons.music_note_outlined;
        break;
      case _FilterType.video:
        message = 'No saved videos yet.\nWatch something calming!';
        icon = Icons.play_circle_outline;
        break;
      case _FilterType.article:
        message = 'No saved articles yet.\nRead and save for later!';
        icon = Icons.article_outlined;
        break;
      case _FilterType.all:
        message = 'Your Calm Kit is empty.\nSave your favorite resources here.';
        icon = Icons.favorite_border;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.white24),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.robotoFlex(
              color: Colors.white60,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _CalmResourceCard extends StatelessWidget {
  const _CalmResourceCard({
    required this.item,
    required this.onTap,
  });

  final _SavedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E325C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full-bleed Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CalmThumb(
                      initials: item.title,
                      type: item.type,
                      thumbnailUrl: item.thumbnailUrl,
                    ),
                    
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),

                    // Type Badge (Top Right)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTypeIcon(item.type),
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.type[0].toUpperCase() + item.type.substring(1),
                              style: GoogleFonts.robotoFlex(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Play Button (Center) for playable media
                    if (item.type != 'article')
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            item.type == 'music' ? Icons.play_arrow_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Text Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.robotoFlex(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.robotoFlex(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      Text(
                         // Display Saved Time (Relative or simple date)
                         _formatDate(item.savedAt),
                         style: GoogleFonts.robotoFlex(
                           fontSize: 10,
                           color: Colors.white.withOpacity(0.4),
                           fontStyle: FontStyle.italic,
                         ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays < 1) {
      return 'Saved today';
    } else if (diff.inDays < 7) {
      return 'Saved ${diff.inDays}d ago';
    }
    return 'Saved ${date.day}/${date.month}/${date.year}';
  }

  IconData _getTypeIcon(String type) {
    if (type == 'music') return Icons.headphones;
    if (type == 'video') return Icons.videocam;
    return Icons.article;
  }
}

class _CalmThumb extends StatelessWidget {
  final String initials;
  final String type;
  final String? thumbnailUrl;

  const _CalmThumb({
    required this.initials, 
    required this.type,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final display = initials.isNotEmpty ? initials[0].toUpperCase() : '?';
    
    Color color1;
    Color color2;
    
    if (type == 'music') {
      color1 = const Color(0xFFB7B9FF);
      color2 = const Color(0xFF6C6EE4);
    } else if (type == 'video') {
      color1 = const Color(0xFFFFB7B2);
      color2 = const Color(0xFFFF80AB);
    } else {
      color1 = const Color(0xFFB2F5EA);
      color2 = const Color(0xFF4FD1C5);
    }

    // No ClipRRect here, parent handles clipping
    return thumbnailUrl != null
        ? Image.network(
            thumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _Placeholder(
              display: display, 
              color1: color1, 
              color2: color2,
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _Placeholder(
                display: display, 
                color1: color1, 
                color2: color2,
              );
            },
          )
        : _Placeholder(
            display: display, 
            color1: color1, 
            color2: color2,
          );
  }
}

class _Placeholder extends StatelessWidget {
  final String display;
  final Color color1;
  final Color color2;

  const _Placeholder({
    required this.display,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          display,
          style: GoogleFonts.robotoFlex(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
