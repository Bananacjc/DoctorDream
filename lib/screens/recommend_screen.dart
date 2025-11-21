import 'package:flutter/material.dart';
import '../data/services/gemini_service.dart';
import '../data/models/user_info.dart';
import '../data/models/music_track.dart';
import '../data/services/youtube_audio_service.dart';
import 'song_player_screen.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  // State management
  bool _isLoading = true;
  String? _error;

  String? _musicRecommendations;
  String? _musicInlineAnswer;
  List<MusicTrack> _musicTracks = [];

  String? _videoRecommendations;
  String? _videoInlineAnswer;

  String? _exerciseRecommendations;
  String? _exerciseInlineAnswer;

  String? _articleRecommendations;
  String? _articleInlineAnswer;

  // User information (emotional state, and other details) - can be updated from other screens or user input
  final UserInfo _userInfo = UserInfo.defaultValues();

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  /// Check if Gemini response is an error message
  bool _isErrorResponse(String response) {
    final lower = response.toLowerCase();
    return lower.contains('sorry') ||
        lower.contains('trouble') ||
        lower.contains('error') ||
        lower.contains('unavailable') ||
        lower.contains('try again') ||
        response.startsWith('(') && response.contains('No');
  }

  /// Main function to fetch all recommendations
  Future<void> _fetchRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch all recommendation types in parallel
      await Future.wait([
        _fetchMusic(),
        // _fetchVideo(),
        // _fetchExercise(),
        // _fetchArticle(),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  /// Fetch music recommendations using Gemini service with retry logic
  Future<void> _fetchMusic({int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelays = [1, 2, 4]; // seconds

    // Set loading state on first attempt or manual retry
    if (retryCount == 0) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Step 1: Get song recommendations from Gemini
      print(
        'Fetching music recommendations from Gemini... (attempt ${retryCount + 1}/$maxRetries)',
      );
      final geminiResult = await GeminiService.instance.recommendMusic(
        userInfo: _userInfo,
        additionalContext: 'Based on my current emotional state and needs',
      );

      if (!mounted) return;

      // Check if Gemini returned an error message instead of recommendations
      if (_isErrorResponse(geminiResult)) {
        if (retryCount < maxRetries) {
          print(
            'Gemini returned error, retrying in ${retryDelays[retryCount]}s...',
          );
          await Future.delayed(Duration(seconds: retryDelays[retryCount]));
          return _fetchMusic(retryCount: retryCount + 1);
        } else {
          throw Exception(
            'Gemini API is temporarily unavailable. Please try again later.',
          );
        }
      }

      print('=== Gemini Music Recommendations ===');
      print(geminiResult);
      print('====================================');

      final tracks = _parseGeminiTracks(geminiResult);

      if (!mounted) return;

      setState(() {
        _musicTracks = tracks;
        _musicInlineAnswer = tracks.isNotEmpty
            ? 'Found ${tracks.length} track(s) for your mood'
            : 'No tracks found from Gemini';
        _error = null; // Clear any previous errors
        _isLoading = false;
      });

      // Fetch thumbnails in the background
      _fetchThumbnails(tracks);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _musicRecommendations = null;
        _musicTracks = [];
        _musicInlineAnswer = 'Unable to load recommendations';
        _error = e.toString().contains('temporarily unavailable')
            ? 'Service temporarily unavailable. Tap to retry.'
            : 'Error loading music recommendations. Tap to retry.';
      });
      print('Error fetching music: $e');
    }
  }

  /// Fetch music thumbnails for tracks in the background
  Future<void> _fetchThumbnails(List<MusicTrack> tracks) async {
    final youtubeService = YoutubeAudioService.instance;
    final updatedTracks = <MusicTrack>[];

    for (final track in tracks) {
      if (track.thumbnailUrl != null) {
        updatedTracks.add(track);
        continue;
      }

      try {
        final thumbnailUrl = await youtubeService.getThumbnailUrl(
          track.buildSearchQuery(),
        );
        if (thumbnailUrl != null && mounted) {
          updatedTracks.add(track.copyWith(thumbnailUrl: thumbnailUrl));
        } else {
          updatedTracks.add(track);
        }
      } catch (_) {
        updatedTracks.add(track);
      }
    }

    if (mounted && updatedTracks.length == tracks.length) {
      setState(() {
        _musicTracks = updatedTracks;
      });
    }
  }

  /// Fetch video recommendations using Gemini service (placeholder for now)
  Future<void> _fetchVideo() async {
    try {
      final result = await GeminiService.instance.recommendVideo(
        userInfo: _userInfo,
        additionalContext: 'Based on my current emotional state and needs',
      );

      if (!mounted) return;
      setState(() {
        _videoRecommendations = result;
        // Extract a preview/summary for inline display (first 100 chars)
        _videoInlineAnswer = result.length > 100
            ? '${result.substring(0, 100)}...'
            : result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoRecommendations = null;
        _videoInlineAnswer = 'Error loading video recommendations';
      });
      print('Error fetching video: $e');
    }
  }

  /// Fetch exercise recommendations (placeholder for future implementation)
  Future<void> _fetchExercise() async {
    // TODO: Implement exercise recommendations
    // This will be implemented later with a specific Gemini prompt for exercises
    if (!mounted) return;
    setState(() {
      _exerciseRecommendations = null;
      _exerciseInlineAnswer = 'Coming soon';
    });
  }

  /// Fetch article recommendations using Gemini service (placeholder for now)
  Future<void> _fetchArticle() async {
    try {
      final result = await GeminiService.instance.generateArticle(
        userInfo: _userInfo,
        topic: 'Helpful content for my current emotional state',
      );

      if (!mounted) return;
      setState(() {
        _articleRecommendations = result;
        // Extract a preview/summary for inline display (first 100 chars)
        _articleInlineAnswer = result.length > 100
            ? '${result.substring(0, 100)}...'
            : result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _articleRecommendations = null;
        _articleInlineAnswer = 'Error loading article';
      });
      print('Error fetching article: $e');
    }
  }

  /// Navigation to song player screen for specific music clicked
  void _openSongPlayer(MusicTrack track) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SongPlayerScreen(track: track)));
  }

  List<MusicTrack> _parseGeminiTracks(String response) {
    final lines = response.split('\n');
    final tracks = <MusicTrack>[];
    final regex = RegExp(
      r'''["“]?([^"”]+)["”]?\s+(?:-|–|—|by)\s+([^-\n]+)''',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(RegExp(r'^[-*•\d\.]+'), '').trim();

      // Pattern: Title - Artist - reason
      final pieces = line.split(' - ').map((e) => e.trim()).toList();
      if (pieces.length >= 2 && pieces[0].isNotEmpty && pieces[1].isNotEmpty) {
        final note = pieces.length > 2
            ? pieces.sublist(2).join(' - ').trim()
            : null;
        tracks.add(
          MusicTrack(
            title: pieces[0],
            artist: pieces[1],
            note: note?.isEmpty == true ? null : note,
          ),
        );
        continue;
      }

      final match = regex.firstMatch(line);
      if (match != null) {
        final title = match.group(1)?.trim();
        final artist = match.group(2)?.trim();
        if (title != null && title.isNotEmpty && artist != null) {
          tracks.add(MusicTrack(title: title, artist: artist));
        }
      }
    }

    return tracks;
  }

  @override
  Widget build(BuildContext context) {
    const Color navy = Color(0xFF081944);
    const Color lightNavy = Color(0xFF0D2357);
    // const Color pillBg = Color(0xFF2E3D6B); // reserved for future use
    const Color accent = Color(0xFFB7B9FF);
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 12.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Recommend today',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Something here but i don''t know',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9AA5C4)),
                    ),
                  ],
                ),
              ),
            ),

            // Category row
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView(
                  padding: pagePadding,
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CategoryPill(
                      label: 'All',
                      icon: Icons.spa_outlined,
                      selected: true,
                    ),
                    _CategoryPill(
                      label: 'Music',
                      icon: Icons.music_note_outlined,
                    ),
                    _CategoryPill(
                      label: 'Video',
                      icon: Icons.play_circle_outline,
                    ),
                    _CategoryPill(
                      label: 'Exercise',
                      icon: Icons.self_improvement_outlined,
                    ),
                    _CategoryPill(
                      label: 'Article',
                      icon: Icons.article_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // Best for you card
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best for you',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: lightNavy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: _PlayGlyph(color: accent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sections: Music, Video, Exercise
            SliverToBoxAdapter(
              child: Padding(
                padding: pagePadding.copyWith(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionRow(
                      title: 'Music',
                      trailing: _isLoading
                          ? 'Loading…'
                          : (_error ??
                                (_musicInlineAnswer ?? 'No recommendations')),
                      onTap: _error != null ? () => _fetchMusic() : null,
                    ),
                    const SizedBox(height: 12),
                    _MusicGrid(
                      isLoading: _isLoading,
                      tracks: _musicTracks,
                      onTrackTap: _openSongPlayer,
                      error: _error,
                      onRetry: _error != null ? () => _fetchMusic() : null,
                    ),
                    const SizedBox(height: 20),
                    _SectionRow(
                      title: 'Video',
                      trailing: _isLoading
                          ? 'Loading…'
                          : (_videoInlineAnswer ?? 'No recommendations'),
                    ),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                    _SectionRow(
                      title: 'Exercise',
                      trailing: _isLoading
                          ? 'Loading…'
                          : (_exerciseInlineAnswer ?? 'Coming soon'),
                    ),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                    _SectionRow(
                      title: 'Article',
                      trailing: _isLoading
                          ? 'Loading…'
                          : (_articleInlineAnswer ?? 'No recommendations'),
                    ),
                    const SizedBox(height: 12),
                    const _CardRow(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  const _CategoryPill({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFB7B9FF).withOpacity(0.25)
                  : const Color(0xFF2E3D6B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFB7B9FF)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFFB4BEDA),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  const _SectionRow({required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              if ((trailing ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: onTap != null
                          ? const Color(0xFFB7B9FF)
                          : const Color(0xFF9AA5C4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          onTap != null ? Icons.refresh : Icons.chevron_right,
          color: const Color(0xFF9AA5C4),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Handle showing the row of the music grid (Parent (1))
class _MusicGrid extends StatelessWidget {
  final bool isLoading;
  final List<MusicTrack> tracks;
  final void Function(MusicTrack) onTrackTap;
  final String? error;
  final VoidCallback? onRetry;

  const _MusicGrid({
    required this.isLoading,
    required this.tracks,
    required this.onTrackTap,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && tracks.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (error != null && tracks.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: const TextStyle(color: Color(0xFF9AA5C4), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB7B9FF),
                    foregroundColor: const Color(0xFF081944),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (tracks.isEmpty) {
      return SizedBox(
        height: 195,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return Container(
              width: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2357),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(child: _PlayGlyph()),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return SizedBox(
            width: 150,
            child: _MusicTrackCard(
              track: track,
              onTap: () => onTrackTap(track),
            ),
          );
        },
      ),
    );
  }
}

/// Specific music song details of GRID card (Child (1a))
class _MusicTrackCard extends StatelessWidget {
  final MusicTrack track;
  final VoidCallback onTap;

  const _MusicTrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF243B6B), Color(0xFF0D2357)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: SizedBox(
          height: 176,
          width: 140,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AlbumThumb(
                  initials: track.title,
                  thumbnailUrl: track.thumbnailUrl,
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1, // Avoid text overflow
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB4BEDA),
                        ),
                      ),

                      if (track.note != null) ...[
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            track.note!,
                            maxLines: 1, // Reduced to 1 to save space
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9AA5C4),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Handle show the specific song thumbnail details (Child (1b))
class _AlbumThumb extends StatelessWidget {
  final String initials;
  final String? thumbnailUrl;

  const _AlbumThumb({required this.initials, this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final display = initials.isNotEmpty ? initials[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: thumbnailUrl != null
            ? Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(display: display),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _Placeholder(display: display);
                },
              )
            : _Placeholder(display: display),
      ),
    );
  }
}

/// Placeholder of thumbnail if failed to load (Child (1c))
class _Placeholder extends StatelessWidget {
  final String display;

  const _Placeholder({required this.display});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB7B9FF), Color(0xFF6C6EE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF0D2357),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: _PlayGlyph()),
          );
        },
      ),
    );
  }
}

/// Play icon in Grid card
class _PlayGlyph extends StatelessWidget {
  final Color color;
  const _PlayGlyph({this.color = const Color(0xFF9AA5C4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.play_arrow_rounded, color: color, size: 20),
    );
  }
}