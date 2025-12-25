import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/article_recommendation.dart';
import '../data/models/music_track.dart';
import '../data/models/video_track.dart';
import '../view_models/recommendation_view_model.dart';
import '../data/services/gemini_service.dart';
import '../data/services/youtube_audio_service.dart';
import '../data/models/recommendation_feedback.dart';
import '../widgets/feedback_popup.dart';
import 'article_screen.dart';
import 'song_player_screen.dart';
import 'video_player_screen.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

enum _RecommendationCategory { all, music, video, article }

class _RecommendScreenState extends State<RecommendScreen> {
  // View model for database access
  late final RecommendationViewModel _viewModel;

  // State management
  bool _isLoading = true;
  String? _error;

  String? _musicInlineAnswer;
  List<MusicTrack> _musicTracks = [];

  String? _videoInlineAnswer;
  List<VideoTrack> _videoTracks = [];

  List<ArticleRecommendation> _articleRecommendations = [];
  bool _isArticleLoading = true;
  String? _articleInlineAnswer;
  String? _articleError;
  bool _isPullRefreshing = false;
  _RecommendationCategory _selectedCategory = _RecommendationCategory.all;
  final TextEditingController _promptController = TextEditingController();
  String? _activePrompt;
  bool _isPromptSubmitting = false;
  bool _hasTypedPrompt = false;

  // Best-for-you pick derived from latest dream
  MusicTrack? _bestMusic;
  VideoTrack? _bestVideo;
  ArticleRecommendation? _bestArticle;

  @override
  void initState() {
    super.initState();
    _viewModel = RecommendationViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _promptController.addListener(() {
      final hasText = _promptController.text.isNotEmpty;
      if (hasText != _hasTypedPrompt) {
        setState(() => _hasTypedPrompt = hasText);
      }
    });
    _initData();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _promptController.dispose();
    super.dispose();
  }

  /// Determine the best item based on latest dream (simple priority)
  void _determineBestRecommendation() {
    if (_viewModel.latestDream == null) {
      _bestMusic = null;
      _bestVideo = null;
      _bestArticle = null;
      return;
    }

    _bestMusic = _musicTracks.isNotEmpty ? _musicTracks.first : null;
    _bestVideo = _bestMusic == null && _videoTracks.isNotEmpty
        ? _videoTracks.first
        : null;
    _bestArticle = _bestMusic == null && _bestVideo == null && _articleRecommendations.isNotEmpty
        ? _articleRecommendations.first
        : null;
  }

  Future<void> _initData() async {
    // Initialize view model (loads user profile and latest dream analysis)
    await _viewModel.initialize();
    if (mounted) {
      _fetchRecommendations();
    }
  }

  /// Build context string that includes dream analysis for recommendations
  String _buildDreamAnalysisContext(String? customPrompt) {
    final buffer = StringBuffer();
    
    if (customPrompt != null && customPrompt.isNotEmpty) {
      buffer.writeln(customPrompt);
    }
    
    final latestDream = _viewModel.latestDream;
    final latestDreamAnalysis = _viewModel.latestDreamAnalysis;
    
    if (latestDream != null && latestDreamAnalysis != null) {
      buffer.writeln('\nBased on my latest dream analysis:');
      buffer.writeln('Dream Title: ${latestDream.dreamTitle}');
      buffer.writeln('Dream Analysis: ${latestDreamAnalysis.analysisContent}');
    } else if (latestDream != null) {
      buffer.writeln('\nBased on my latest dream:');
      buffer.writeln('Dream Title: ${latestDream.dreamTitle}');
      buffer.writeln('Dream Content: ${latestDream.dreamContent}');
    }
    
    // Add feedback context if available
    final feedback = _viewModel.currentDreamFeedback;
    if (feedback.isNotEmpty) {
      buffer.writeln('\nMy feedback on previous recommendations for this dream:');
      for (final fb in feedback) {
        buffer.writeln('- I rated "${fb.recommendationId}" ${fb.rating}/5 stars.');
        if (fb.comment != null && fb.comment!.isNotEmpty) {
          buffer.writeln('  Comment: "${fb.comment}"');
        }
      }
      buffer.writeln('Please use this feedback to refine new recommendations.');
    }
    
    return buffer.toString().trim();
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
  Future<void> _fetchRecommendations({String? prompt}) async {
    final effectivePrompt = prompt ?? _activePrompt;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch all recommendation types in parallel
      await Future.wait([
        _fetchMusic(customPrompt: effectivePrompt),
        _fetchArticles(customPrompt: effectivePrompt),
        _fetchVideo(customPrompt: effectivePrompt),
      ]);

      _determineBestRecommendation();

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

  Future<void> _handlePullToRefresh() async {
    if (_isPullRefreshing) return;
    
    setState(() {
      _isPullRefreshing = true;
      _isLoading = true;
      _error = null;
      _musicTracks = [];
      _musicInlineAnswer = null;
      _videoTracks = [];
      _videoInlineAnswer = null;
      _isArticleLoading = true;
      _articleRecommendations = [];
      _articleInlineAnswer = null;
      _articleError = null;
      _bestMusic = null;
      _bestVideo = null;
      _bestArticle = null;
    });
    
    try {
      await _viewModel.loadLatestDreamAnalysis();
      await _fetchRecommendations();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPullRefreshing = false;
        });
      }
    }
  }

  void _onCategorySelected(_RecommendationCategory category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
  }

  Future<void> _submitPrompt() async {
    final trimmed = _promptController.text.trim();
    final prompt = trimmed.isEmpty ? null : trimmed;

    if (_isPromptSubmitting) return;

    setState(() {
      _activePrompt = prompt;
      _promptController.clear();
      _hasTypedPrompt = false;
      _isPromptSubmitting = true;
      _isLoading = true;
      _musicTracks = [];
      _musicInlineAnswer = null;
      _videoTracks = [];
      _videoInlineAnswer = null;
      _isArticleLoading = true;
      _articleRecommendations = [];
      _bestMusic = null;
      _bestVideo = null;
      _bestArticle = null;
    });

    // Reload latest dream analysis before fetching recommendations
    await _viewModel.loadLatestDreamAnalysis();
    await _fetchRecommendations(prompt: _activePrompt);
    setState(() => _isPromptSubmitting = false);
  }

  bool _shouldShowCategory(_RecommendationCategory category) {
    return _selectedCategory == _RecommendationCategory.all ||
        _selectedCategory == category;
  }

  /// Fetch music recommendations using Gemini service with retry logic
  Future<void> _fetchMusic({int retryCount = 0, String? customPrompt}) async {
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
      final context = _buildDreamAnalysisContext(customPrompt);
      final geminiResult = await GeminiService.instance.recommendMusic(
        userInfo: _viewModel.userInfo,
        additionalContext: context.isNotEmpty
            ? context
            : 'Based on my current emotional state and needs',
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
            ? 'Found ${tracks.length} track(s) for you'
            : 'No tracks found from Gemini';
        _error = null; // Clear any previous errors
        _isLoading = false;
      });

      // Fetch thumbnails in the background
      _fetchThumbnails(tracks);
    } catch (e) {
      if (!mounted) return;
      setState(() {
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

  /// Fetch video recommendations using Gemini service with retry logic
  Future<void> _fetchVideo({int retryCount = 0, String? customPrompt}) async {
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
      // Step 1: Get video recommendations from Gemini
      print(
        'Fetching video recommendations from Gemini... (attempt ${retryCount + 1}/$maxRetries)',
      );
      final context = _buildDreamAnalysisContext(customPrompt);
      final geminiResult = await GeminiService.instance.recommendVideo(
        userInfo: _viewModel.userInfo,
        additionalContext: context.isNotEmpty
            ? context
            : 'Based on my current emotional state and needs',
      );

      if (!mounted) return;

      // Check if Gemini returned an error message instead of recommendations
      if (_isErrorResponse(geminiResult)) {
        if (retryCount < maxRetries) {
          print(
            'Gemini returned error, retrying in ${retryDelays[retryCount]}s...',
          );
          await Future.delayed(Duration(seconds: retryDelays[retryCount]));
          return _fetchVideo(retryCount: retryCount + 1, customPrompt: customPrompt);
        } else {
          throw Exception(
            'Gemini API is temporarily unavailable. Please try again later.',
          );
        }
      }

      print('=== Gemini Video Recommendations ===');
      print(geminiResult);
      print('====================================');

      final tracks = _parseGeminiVideos(geminiResult);

      if (!mounted) return;

      setState(() {
        _videoTracks = tracks;
        _videoInlineAnswer = tracks.isNotEmpty
            ? 'Found ${tracks.length} video(s) for you'
            : 'No videos found from Gemini';
        _error = null; // Clear any previous errors
        _isLoading = false;
      });

      // Fetch video details (ID, URL, thumbnails) in the background
      _fetchVideoDetails(tracks);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoTracks = [];
        _videoInlineAnswer = 'Unable to load recommendations';
        _error = e.toString().contains('temporarily unavailable')
            ? 'Service temporarily unavailable. Tap to retry.'
            : 'Error loading video recommendations. Tap to retry.';
      });
      print('Error fetching video: $e');
    }
  }

  /// Strip markdown formatting from text (e.g., **[text](url)** -> text)
  String _stripMarkdown(String text) {
    // Remove markdown links: [text](url) -> text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Remove bold/italic markers: **text** or *text* -> text
    text = text.replaceAllMapped(
      RegExp(r'\*{1,2}([^\*]+)\*{1,2}'),
      (match) => match.group(1) ?? '',
    );
    // Remove any remaining markdown formatting
    text = text.replaceAll(RegExp(r'[\[\]()*_`]'), '');
    return text.trim();
  }

  /// Extract URL from markdown link if present: [text](url) -> url
  String? _extractUrlFromMarkdown(String text) {
    final markdownUrlMatch = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)').firstMatch(text);
    if (markdownUrlMatch != null) {
      final url = markdownUrlMatch.group(2);
      if (url != null && url.isNotEmpty) {
        return url.trim();
      }
    }
    return null;
  }

  /// Parse Gemini response to extract video recommendations
  List<VideoTrack> _parseGeminiVideos(String response) {
    final lines = response.split('\n');
    final tracks = <VideoTrack>[];
    final regex = RegExp(
      r'''[""]?([^""]+)[""]?\s+(?:-|–|—|by)\s+([^-\n]+)''',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(RegExp(r'^[-*•\d\.]+'), '').trim();

      // Pattern: Title - Channel - reason
      final pieces = line.split(' - ').map((e) => e.trim()).toList();
      if (pieces.length >= 2 && pieces[0].isNotEmpty && pieces[1].isNotEmpty) {
        final rawTitle = pieces[0];
        final title = _stripMarkdown(rawTitle);
        final channel = _stripMarkdown(pieces[1]);
        final note = pieces.length > 2
            ? _stripMarkdown(pieces.sublist(2).join(' - ').trim())
            : null;
        
        // Extract video URL from markdown if present in title
        final videoUrl = _extractUrlFromMarkdown(rawTitle);
        
        tracks.add(
          VideoTrack(
            title: title,
            channel: channel,
            note: note?.isEmpty == true ? null : note,
            videoUrl: videoUrl,
          ),
        );
        continue;
      }

      final match = regex.firstMatch(line);
      if (match != null) {
        final title = _stripMarkdown(match.group(1)?.trim() ?? '');
        final channel = _stripMarkdown(match.group(2)?.trim() ?? '');
        if (title.isNotEmpty && channel.isNotEmpty) {
          tracks.add(VideoTrack(title: title, channel: channel));
        }
      }
    }

    return tracks;
  }

  /// Fetch video details (ID, URL, thumbnails) for tracks in the background
  Future<void> _fetchVideoDetails(List<VideoTrack> tracks) async {
    final youtubeService = YoutubeAudioService.instance;
    final updatedTracks = <VideoTrack>[];

    for (final track in tracks) {
      if (track.videoId != null && track.thumbnailUrl != null) {
        updatedTracks.add(track);
        continue;
      }

      // Try to fetch video details with retry logic
      Map<String, dynamic>? details;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries && (details == null || details.isEmpty)) {
        try {
          details = await youtubeService.getVideoDetails(
            track.buildSearchQuery(),
          );
          
          if (details.isNotEmpty && details['videoId'] != null) {
            break; // Success, exit retry loop
          }
          
          // If no results and we have retries left, try again
          if (retryCount < maxRetries) {
            retryCount++;
            // Wait a bit before retrying
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            details = null; // Reset to try again
          }
        } catch (e) {
          print('Error fetching video details for "${track.title}": $e');
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          } else {
            details = null;
          }
        }
      }

      if (mounted && details != null && details.isNotEmpty) {
        updatedTracks.add(
          track.copyWith(
            videoId: details['videoId'],
            videoUrl: details['videoUrl'],
            thumbnailUrl: details['thumbnailUrl'] ?? track.thumbnailUrl,
            channel: details['channel'] ?? track.channel,
          ),
        );
      } else {
        // Keep original track even if we couldn't fetch details
        updatedTracks.add(track);
      }
    }

    if (mounted && updatedTracks.length == tracks.length) {
      setState(() {
        _videoTracks = updatedTracks;
      });
    }
  }

  /// Fetch article recommendations using Gemini service
  Future<void> _fetchArticles({String? customPrompt}) async {
    setState(() {
      _isArticleLoading = true;
      _articleError = null;
    });

    try {
      final context = _buildDreamAnalysisContext(customPrompt);
      final articles = await GeminiService.instance.recommendArticles(
        userInfo: _viewModel.userInfo,
        count: 4,
        personalizationPrompt: context.isNotEmpty ? context : customPrompt,
      );

      if (!mounted) return;
      setState(() {
        _articleRecommendations = articles;
        _articleInlineAnswer = articles.isNotEmpty
            ? 'Found ${articles.length} helpful reads'
            : 'No recommendations yet';
        _isArticleLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _articleRecommendations = [];
        _articleInlineAnswer = 'Unable to load articles';
        _articleError = 'Error loading articles. Tap to retry.';
        _isArticleLoading = false;
      });
      print('Error fetching articles: $e');
    }
  }

  /// Check if feedback is needed and show popup based on counter logic
  Future<void> _checkAndShowFeedback({
    required String recommendationId,
    required String type,
    required String title,
  }) async {
    if (_viewModel.latestDream == null) return;
    
    // 1. Check if user has already given feedback for this specific item
    final dreamId = _viewModel.latestDream!.dreamID;
    final hasFeedback = await _viewModel.hasFeedback(
      recommendationId,
      dreamId,
    );

    if (hasFeedback) return;

    // 2. Increment session counter
    final prefs = await SharedPreferences.getInstance();
    int currentCount = (prefs.getInt('feedback_item_count') ?? 0) + 1;
    await prefs.setInt('feedback_item_count', currentCount);

    // 3. Only show popup every 4 items (adjust number as needed)
    if (currentCount % 4 != 0) {
      print('Feedback skipped. Count: $currentCount');
      return; 
    }

    if (!mounted) return;

    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Show feedback popup
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Feedback",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: FeedbackPopup(
              title: title,
              onSubmit: (rating, comment) async {
                final feedback = RecommendationFeedback(
                  recommendationId: recommendationId,
                  type: type,
                  rating: rating,
                  comment: comment,
                  relatedDreamId: dreamId,
                  timestamp: DateTime.now(),
                );

                await _viewModel.saveFeedback(feedback);
              },
            ),
          ),
        );
      },
    );
  }

  /// Navigation to song player screen for specific music clicked
  void _openSongPlayer(MusicTrack track) async {
    // Dismiss keyboard if open
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SongPlayerScreen(track: track)));

    if (mounted) {
      // Ensure focus is cleared when returning
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      // Use title + artist as unique ID for music
      final recId = '${track.title} - ${track.artist}';
      _checkAndShowFeedback(
        recommendationId: recId,
        type: 'music',
        title: track.title,
      );
    }
  }

  void _openArticle(ArticleRecommendation article) {
    // Dismiss keyboard if open
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ArticleScreen(article: article)));
  }

  void _openVideo(VideoTrack track) async {
    // Dismiss keyboard if open
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(track: track),
      ),
    );

    if (mounted) {
      // Ensure focus is cleared when returning
      FocusScope.of(context).unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');

      // Use videoId or title+channel as ID
      final recId = track.videoId ?? '${track.title} - ${track.channel ?? ""}';
      _checkAndShowFeedback(
        recommendationId: recId,
        type: 'video',
        title: track.title,
      );
    }
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
    const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
            child: RefreshIndicator(
              color: Colors.white,
              backgroundColor: navy,
              onRefresh: _handlePullToRefresh,
              child: CustomScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                  padding: pagePadding.copyWith(top: 0, bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Recommend today',
                        style: GoogleFonts.robotoFlex(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              // Category row
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding,
                  child: SizedBox(
                    height: 88,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _CategoryPill(
                          label: 'All',
                          icon: Icons.spa_outlined,
                          selected:
                              _selectedCategory == _RecommendationCategory.all,
                          onTap: () =>
                              _onCategorySelected(_RecommendationCategory.all),
                        ),
                        _CategoryPill(
                          label: 'Music',
                          icon: Icons.music_note_outlined,
                          selected:
                              _selectedCategory == _RecommendationCategory.music,
                          onTap: () =>
                              _onCategorySelected(_RecommendationCategory.music),
                        ),
                        _CategoryPill(
                          label: 'Video',
                          icon: Icons.play_circle_outline,
                          selected:
                              _selectedCategory == _RecommendationCategory.video,
                          onTap: () =>
                              _onCategorySelected(_RecommendationCategory.video),
                        ),
                        _CategoryPill(
                          label: 'Article',
                          icon: Icons.article_outlined,
                          selected:
                              _selectedCategory ==
                              _RecommendationCategory.article,
                          onTap: () => _onCategorySelected(
                            _RecommendationCategory.article,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 12, bottom: 12),
                  child: TextField(
                    controller: _promptController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _hasTypedPrompt
                          ? ''
                          : 'Ask for a different song/video/article…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_activePrompt != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _promptController.clear();
                                if (_activePrompt != null) {
                                  setState(() => _activePrompt = null);
                                  _fetchRecommendations(prompt: null);
                                }
                              },
                            ),
                          if (_hasTypedPrompt)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: _isPromptSubmitting
                                    ? null
                                    : _submitPrompt,
                                style: ElevatedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  backgroundColor: _isPromptSubmitting
                                      ? Colors.white24
                                      : const Color(0xFFB7B9FF),
                                  foregroundColor: const Color(0xFF081944),
                                  padding: const EdgeInsets.all(10),
                                ),
                                child: _isPromptSubmitting
                                    ? const SizedBox(
                                        height: 14,
                                        width: 14,
                                        child: _ShimmerSkeleton(
                                          width: 14,
                                          height: 14,
                                          borderRadius: BorderRadius.all(Radius.circular(7)),
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded, size: 18),
                              ),
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: lightNavy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Best for you card (based on latest dream)
              if (_selectedCategory == _RecommendationCategory.all &&
                  (_bestMusic != null || _bestVideo != null || _bestArticle != null))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: pagePadding.copyWith(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best for you',
                          style: GoogleFonts.robotoFlex(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _BestForYouCard(
                          music: _bestMusic,
                          video: _bestVideo,
                          article: _bestArticle,
                          onMusicTap: _bestMusic != null
                              ? () => _openSongPlayer(_bestMusic!)
                              : null,
                          onVideoTap: _bestVideo != null
                              ? () => _openVideo(_bestVideo!)
                              : null,
                          onArticleTap: _bestArticle != null
                              ? () => _openArticle(_bestArticle!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

              // Sections: Music, Video, Article
              SliverToBoxAdapter(
                child: Padding(
                  padding: pagePadding.copyWith(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_shouldShowCategory(
                        _RecommendationCategory.music,
                      )) ...[
                        _SectionRow(
                          title: 'Music',
                          trailing: _isLoading
                              ? 'Loading…'
                              : (_error ??
                                    (_musicInlineAnswer ??
                                        'No recommendations')),
                          onTap: _error != null ? () => _fetchMusic() : null,
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1.5,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        _MusicGrid(
                          isLoading: _isLoading,
                          tracks: _musicTracks,
                          onTrackTap: _openSongPlayer,
                          error: _error,
                          onRetry: _error != null ? () => _fetchMusic() : null,
                          layout:
                              _selectedCategory == _RecommendationCategory.music
                              ? MusicLayout.grid
                              : MusicLayout.carousel,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_shouldShowCategory(
                        _RecommendationCategory.video,
                      )) ...[
                        _SectionRow(
                          title: 'Video',
                          trailing: _isLoading
                              ? 'Loading…'
                              : (_error ??
                                    (_videoInlineAnswer ??
                                        'No recommendations')),
                          onTap: _error != null ? () => _fetchVideo() : null,
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1.5,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        _VideoGrid(
                          isLoading: _isLoading,
                          tracks: _videoTracks,
                          onTrackTap: _openVideo,
                          error: _error,
                          onRetry: _error != null ? () => _fetchVideo() : null,
                          layout:
                              _selectedCategory == _RecommendationCategory.video
                              ? VideoLayout.grid
                              : VideoLayout.carousel,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_shouldShowCategory(
                        _RecommendationCategory.article,
                      )) ...[
                        _SectionRow(
                          title: 'Article',
                          trailing: _isArticleLoading
                              ? 'Loading…'
                              : (_articleError ??
                                    (_articleInlineAnswer ??
                                        'No recommendations')),
                          onTap: _articleError != null ? _fetchArticles : null,
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          color: Colors.white.withOpacity(0.3),
                          thickness: 1.5,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        _selectedCategory == _RecommendationCategory.article
                            ? _ArticleGridExpanded(
                                isLoading: _isArticleLoading,
                                articles: _articleRecommendations,
                                error: _articleError,
                                onRetry: _articleError != null
                                    ? _fetchArticles
                                    : null,
                                onArticleTap: _openArticle,
                              )
                            : _ArticleCarousel(
                                isLoading: _isArticleLoading,
                                articles: _articleRecommendations,
                                error: _articleError,
                                onRetry: _articleError != null
                                    ? _fetchArticles
                                    : null,
                                onArticleTap: _openArticle,
                              ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )));
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const _CategoryPill({
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFB7B9FF)
                  : const Color(0xFF2E3D6B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                icon,
                color: selected
                    ? const Color(0xFF081944)
                    : const Color(0xFFB7B9FF),
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.robotoFlex(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFFB4BEDA),
            ),
            textAlign: TextAlign.center,
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
              Text(title, style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700)),
              if ((trailing ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trailing!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoFlex(
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
        if (onTap != null)
          Icon(
            Icons.refresh,
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
enum MusicLayout { carousel, grid }

/// Handle showing the row of the video grid
enum VideoLayout { carousel, grid }

class _MusicGrid extends StatelessWidget {
  final bool isLoading;
  final List<MusicTrack> tracks;
  final void Function(MusicTrack) onTrackTap;
  final String? error;
  final VoidCallback? onRetry;
  final MusicLayout layout;

  const _MusicGrid({
    required this.isLoading,
    required this.tracks,
    required this.onTrackTap,
    this.error,
    this.onRetry,
    this.layout = MusicLayout.carousel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && tracks.isEmpty) {
      return layout == MusicLayout.grid
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _MusicSkeletonCard();
              },
            )
          : SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 150,
                    child: _MusicSkeletonCard(),
                  );
                },
              ),
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
                style: GoogleFonts.robotoFlex(color: Color(0xFF9AA5C4), fontSize: 12),
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
      return layout == MusicLayout.grid
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: List.generate(
                4,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
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
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: const Center(child: _PlayGlyph()),
                  );
                },
              ),
            );
    }

    if (layout == MusicLayout.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _MusicTrackCard(track: track, onTap: () => onTrackTap(track));
        },
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

class _VideoGrid extends StatelessWidget {
  final bool isLoading;
  final List<VideoTrack> tracks;
  final void Function(VideoTrack) onTrackTap;
  final String? error;
  final VoidCallback? onRetry;
  final VideoLayout layout;

  const _VideoGrid({
    required this.isLoading,
    required this.tracks,
    required this.onTrackTap,
    this.error,
    this.onRetry,
    this.layout = VideoLayout.carousel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && tracks.isEmpty) {
      return layout == VideoLayout.grid
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.7,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _VideoSkeletonCard();
              },
            )
          : SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 150,
                    child: _VideoSkeletonCard(),
                  );
                },
              ),
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
                style: GoogleFonts.robotoFlex(color: Color(0xFF9AA5C4), fontSize: 12),
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
      return layout == VideoLayout.grid
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
              children: List.generate(
                4,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
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
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: const Center(child: _PlayGlyph()),
                  );
                },
              ),
            );
    }

    if (layout == VideoLayout.grid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _VideoTrackCard(track: track, onTap: () => onTrackTap(track));
        },
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
            child: _VideoTrackCard(
              track: track,
              onTap: () => onTrackTap(track),
            ),
          );
        },
      ),
    );
  }
}

class _VideoTrackCard extends StatelessWidget {
  final VideoTrack track;
  final VoidCallback onTap;

  const _VideoTrackCard({required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _VideoThumb(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.robotoFlex(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (track.channel != null)
                        Text(
                          track.channel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoFlex(
                            fontSize: 12,
                            color: Color(0xFFB4BEDA),
                          ),
                        ),

                      if (track.note != null) ...[
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            track.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.robotoFlex(
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
    );
  }
}

class _VideoThumb extends StatelessWidget {
  final String initials;
  final String? thumbnailUrl;

  const _VideoThumb({required this.initials, this.thumbnailUrl});

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

class _ArticleCarousel extends StatelessWidget {
  final bool isLoading;
  final List<ArticleRecommendation> articles;
  final void Function(ArticleRecommendation) onArticleTap;
  final String? error;
  final VoidCallback? onRetry;

  const _ArticleCarousel({
    required this.isLoading,
    required this.articles,
    required this.onArticleTap,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const carouselHeight = 180.0;

    if (isLoading && articles.isEmpty) {
      return SizedBox(
        height: carouselHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          padding: EdgeInsets.zero,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return SizedBox(
              width: 220,
              child: _ArticleSkeletonCard(),
            );
          },
        ),
      );
    }

    if (error != null && articles.isEmpty) {
      return SizedBox(
        height: carouselHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: GoogleFonts.robotoFlex(color: Color(0xFF9AA5C4), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final items = articles.isEmpty ? List.filled(4, null) : articles;

    return SizedBox(
      height: carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: EdgeInsets.zero,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final article = items[index];
          return SizedBox(
            width: 220,
            child: article == null
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  )
                : _ArticleCard(
                    article: article,
                    onTap: () => onArticleTap(article),
                  ),
          );
        },
      ),
    );
  }
}

class _ArticleGridExpanded extends StatelessWidget {
  final bool isLoading;
  final List<ArticleRecommendation> articles;
  final void Function(ArticleRecommendation) onArticleTap;
  final String? error;
  final VoidCallback? onRetry;

  const _ArticleGridExpanded({
    required this.isLoading,
    required this.articles,
    required this.onArticleTap,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && articles.isEmpty) {
      final rowCount = 2; // 2 rows for 4 items
      final itemHeight = 200.0;
      final spacing = 12.0;
      final totalHeight = (rowCount * itemHeight) + ((rowCount - 1) * spacing);

      return SizedBox(
        height: totalHeight,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return _ArticleSkeletonCard();
          },
        ),
      );
    }

    if (error != null && articles.isEmpty) {
      return Column(
        children: [
          Text(
            error!,
            style: GoogleFonts.robotoFlex(color: Color(0xFF9AA5C4), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ],
      );
    }

    final items = articles.isEmpty
        ? List<ArticleRecommendation?>.filled(4, null)
        : articles;

    // Calculate height based on number of items
    // 2 columns, so rows = (items.length / 2).ceil()
    // Each row height = (width / 2 - spacing) / aspectRatio + spacing
    // For safety, use a minimum height per item
    final rowCount = (items.length / 2).ceil();
    final itemHeight = 200.0; // Approximate height per item
    final spacing = 12.0;
    final totalHeight = (rowCount * itemHeight) + ((rowCount - 1) * spacing);

    return SizedBox(
      height: totalHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final article = items[index];
          if (article == null) {
            return Container(
              decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            );
          }
          return _ArticleCard(
            article: article,
            onTap: () => onArticleTap(article),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final ArticleRecommendation article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatArticlePreview(article.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoFlex(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatArticlePreview(article.summary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.robotoFlex(
                    color: Color(0xFFB4BEDA),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      (article.tags.isNotEmpty
                              ? article.tags.take(2)
                              : const ['Mindfulness'])
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFB7B9FF,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.robotoFlex(
                                  color: Color(0xFFB7B9FF),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatArticlePreview(String text) {
  var result = text;
  result = result.replaceAll(RegExp(r'#{1,6}\s*'), '');
  result = result.replaceAll('**', '');
  result = result.replaceAll('*', '');
  result = result.replaceAll('`', '');
  result = result.replaceAllMapped(
    RegExp(r'\[(.*?)\]\((.*?)\)'),
    (match) => match.group(1) ?? '',
  );
  result = result.replaceAll(RegExp(r'(\r?\n)+'), ' ');
  return result.trim();
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
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                        style: GoogleFonts.robotoFlex(
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
                        style: GoogleFonts.robotoFlex(
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
                            style: GoogleFonts.robotoFlex(
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
          style: GoogleFonts.robotoFlex(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Best for you card widget
class _BestForYouCard extends StatelessWidget {
  final MusicTrack? music;
  final VideoTrack? video;
  final ArticleRecommendation? article;
  final VoidCallback? onMusicTap;
  final VoidCallback? onVideoTap;
  final VoidCallback? onArticleTap;

  const _BestForYouCard({
    this.music,
    this.video,
    this.article,
    this.onMusicTap,
    this.onVideoTap,
    this.onArticleTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMusic = music != null;
    final bool isVideo = !isMusic && video != null;
    // final bool isArticle = !isMusic && !isVideo && article != null;

    final String title = isMusic
        ? music!.title
        : isVideo
            ? video!.title
            : article?.title ?? '';
    final String subtitle = isMusic
        ? music!.artist
        : isVideo
            ? (video!.channel ?? '')
            : (article?.summary ?? '');

    final IconData icon = isMusic
        ? Icons.music_note
        : isVideo
            ? Icons.play_circle
            : Icons.article;

    final String? thumbnail = isMusic
        ? music!.thumbnailUrl
        : isVideo
            ? video!.thumbnailUrl
            : null;

    final VoidCallback? onTap =
        isMusic ? onMusicTap : isVideo ? onVideoTap : onArticleTap;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: thumbnail == null
                      ? const LinearGradient(
                          colors: [Color(0xFFB7B9FF), Color(0xFF6C6EE4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: thumbnail != null
                      ? DecorationImage(
                          image: NetworkImage(thumbnail),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: thumbnail == null
                    ? Icon(icon, color: Colors.white, size: 36)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: const Color(0xFFB7B9FF), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isMusic
                              ? 'Music'
                              : isVideo
                                  ? 'Video'
                                  : 'Article',
                          style: GoogleFonts.robotoFlex(
                            color: Color(0xFFB7B9FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoFlex(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoFlex(
                        fontSize: 12,
                        color: Color(0xFFB4BEDA),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _PlayGlyph(color: Color(0xFFB7B9FF)),
            ],
          ),
        ),
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

/// Music skeleton card for loading state
class _MusicSkeletonCard extends StatelessWidget {
  const _MusicSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _ShimmerSkeleton(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E3D6B),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. The Image Placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: const Color(0xFF2E3D6B),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. The Text Placeholders (Wrapped in Expanded to prevent overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D6B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D6B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Removed the 3rd line to save vertical space
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

class _VideoSkeletonCard extends StatelessWidget {
  const _VideoSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _ShimmerSkeleton(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E3D6B),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: const Color(0xFF2E3D6B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D6B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3D6B),
                        borderRadius: BorderRadius.circular(4),
                      ),
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

/// Article skeleton card for loading state
class _ArticleSkeletonCard extends StatelessWidget {
  const _ArticleSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return _ShimmerSkeleton(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2E3D6B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D6B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D6B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D6B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E3D6B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3D6B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 20,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E3D6B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton loading widget with dark mode theme
class _ShimmerSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const _ShimmerSkeleton({
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dimensions safely
        final width = widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0);
        final height = widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 100.0);

        // Define the width of the shimmer beam (e.g., 50% of the content width)
        final shimmerWidth = width * 0.5;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate exact position to move from left (outside) to right (outside)
            // Range: -shimmerWidth to width
            final offset = (width + shimmerWidth) * _controller.value - shimmerWidth;

            // Common shimmer gradient
            final gradientDecoration = BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
            );

            // Structure 1: Wrapping a child widget (Skeleton Cards)
            if (widget.child != null) {
              return ClipRRect(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                child: Stack(
                  clipBehavior: Clip.hardEdge, // Crucial: prevents overflow
                  children: [
                    // The background content (grey boxes)
                    widget.child!,

                    // The moving Shimmer Overlay
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: shimmerWidth, // Explicit width
                      child: Transform.translate(
                        offset: Offset(offset, 0),
                        child: Container(
                          decoration: gradientDecoration,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Structure 2: Standalone loading block (if used without child)
            return ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // Base background
                  Container(
                    width: width,
                    height: height,
                    color: const Color(0xFF2E3D6B),
                  ),
                  // Moving shimmer
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: shimmerWidth,
                    child: Transform.translate(
                      offset: Offset(offset, 0),
                      child: Container(
                        decoration: gradientDecoration,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
