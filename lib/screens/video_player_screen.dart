// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../data/models/video_track.dart';
import '../data/services/youtube_audio_service.dart';
import '../data/local/local_database.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.track});

  final VideoTrack track;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  final YoutubeAudioService _youtubeService = YoutubeAudioService.instance;

  bool _isLoading = true;
  String? _error;
  String? _videoId;
  Timer? _positionTimer;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _initializePlayer();
  }

  Future<void> _checkIfSaved() async {
    final isSaved = await LocalDatabase.instance.isVideoSaved(widget.track);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await LocalDatabase.instance.removeVideo(widget.track);
    } else {
      await LocalDatabase.instance.saveVideo(widget.track);
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

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String? videoId;

      // Try to get video ID from track
      if (widget.track.videoId != null) {
        videoId = widget.track.videoId!.trim();
        print('\n========== VIDEO PLAYER SCREEN DEBUG ==========');
        print('Video: ${widget.track.title}');
        print('Video ID (from track): $videoId');
        print('=============================================\n');
      } else if (widget.track.videoUrl != null) {
        // Extract URL from markdown if present: [text](url) -> url
        String url = widget.track.videoUrl!;
        final markdownUrlMatch = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)').firstMatch(url);
        if (markdownUrlMatch != null) {
          url = markdownUrlMatch.group(2) ?? url;
        }
        
        // Extract ID from URL
        final extractedId = YoutubePlayer.convertUrlToId(url);
        videoId = extractedId?.trim();
        print('\n========== VIDEO PLAYER SCREEN DEBUG ==========');
        print('Video: ${widget.track.title}');
        print('Video URL: $url');
        print('Extracted Video ID: $videoId');
        print('=============================================\n');
      }

      // If still no video ID, search YouTube with retry logic
      if (videoId == null || videoId.isEmpty) {
        print('No video ID found, searching YouTube...');
        final query = widget.track.buildSearchQuery();
        print('Search Query: "$query"');

        Map<String, dynamic>? details;
        int retryCount = 0;
        const maxRetries = 2;

        while (retryCount <= maxRetries && (details == null || details.isEmpty || details['videoId'] == null)) {
          try {
            details = await _youtubeService.getVideoDetails(query);
            if (details.isNotEmpty && details['videoId'] != null) {
              videoId = (details['videoId'] as String).trim();
              print('Found Video ID from search: $videoId');
              break; // Success, exit retry loop
            }
            
            // If no results and we have retries left, try again
            if (retryCount < maxRetries) {
              retryCount++;
              print('Retry $retryCount/$maxRetries: Searching again...');
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
              details = null; // Reset to try again
            } else {
              throw Exception('Could not find video ID for: ${widget.track.title}');
            }
          } catch (e) {
            if (retryCount < maxRetries) {
              retryCount++;
              print('Error on search, retry $retryCount/$maxRetries: $e');
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            } else {
              rethrow;
            }
          }
        }
      }

      if (videoId == null || videoId.isEmpty) {
        throw Exception('Invalid video ID');
      }

      if (!mounted) return;

      // At this point, videoId is guaranteed to be non-null after the check above
      final finalVideoId = videoId;
      _videoId = finalVideoId;

      // Initialize YouTube player controller
      _controller = YoutubePlayerController(
        initialVideoId: finalVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          loop: false,
          isLive: false,
        ),
      );

      // Listen to player state changes
      _controller!.addListener(_playerListener);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      print('✓ YouTube player initialized with ID: $videoId');
      print('=============================================\n');
    } catch (e, stackTrace) {
      print('\n========== VIDEO PLAYER ERROR ==========');
      print('✗ Failed to initialize YouTube player');
      print('Video: ${widget.track.title}');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      print('=======================================\n');

      if (!mounted) return;
      setState(() {
        String errorMsg = 'Could not play this video. ';

        if (e.toString().contains('Could not find video ID')) {
          errorMsg += 'Video not found on YouTube.';
        } else if (e.toString().contains('Invalid video ID')) {
          errorMsg += 'Invalid video ID.';
        } else {
          errorMsg += 'Try another video.';
        }

        _error = errorMsg;
        _isLoading = false;
      });
    }
  }

  void _playerListener() {
    if (!mounted || _controller == null) return;
    final playerState = _controller!.value.playerState;

    // Update position and duration
    final position = _controller!.value.position;
    final duration = _controller!.value.metaData.duration;

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _totalDuration = duration;
      });
    }

    // Handle errors
    if (playerState == PlayerState.unknown) {
      // Player might be loading or errored
      if (_controller!.value.hasError) {
        if (mounted) {
          setState(() {
            _error = 'Video playback error. Please try again.';
          });
        }
      }
    }
  }

  void _seekTo(Duration position) {
    if (_controller != null) {
      _controller!.seekTo(position);
    }
  }

  void _rewind10Seconds() {
    if (_controller != null) {
      final newPosition = _currentPosition - const Duration(seconds: 10);
      _seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    }
  }

  void _fastForward10Seconds() {
    if (_controller != null) {
      final newPosition = _currentPosition + const Duration(seconds: 10);
      _seekTo(newPosition > _totalDuration ? _totalDuration : newPosition);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _reloadPlayer() async {
    if (_videoId == null) {
      await _initializePlayer();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _controller?.pause();
      _controller?.dispose();
      _controller = null;

      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          loop: false,
          isLive: false,
        ),
      );

      _controller!.addListener(_playerListener);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to reload video. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Strip markdown formatting from text
  String _stripMarkdown(String text) {
    // Remove markdown links: [text](url) -> text
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    // Remove bold/italic markers: **text** or *text* -> text
    text = text.replaceAll(RegExp(r'\*{1,2}([^\*]+)\*{1,2}'), r'$1');
    // Remove any remaining markdown formatting
    text = text.replaceAll(RegExp(r'[\[\]()*_`]'), '');
    return text.trim();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081944),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Now Playing',
          style: TextStyle(color: Colors.white),
        ),
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
      body: SafeArea(
        child: Column(
          children: [
            // Video player area
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Center(
                  child: _isLoading
                      ? const Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading video…',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _reloadPlayer,
                                    child: const Text('Try Again'),
                                  ),
                                ],
                              ),
                            )
                          : _controller != null
                              ? YoutubePlayerBuilder(
                                  player: YoutubePlayer(
                                    controller: _controller!,
                                    showVideoProgressIndicator: false,
                                    onReady: () {
                                      print('✓ YouTube player ready');
                                    },
                                    onEnded: (metadata) {
                                      print('Video ended');
                                    },
                                  ),
                                  builder: (context, player) {
                                    return player;
                                  },
                                )
                              : const SizedBox(),
                ),
              ),
            ),
            // Video info and controls section
            Expanded(
              flex: 3,
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Video name
                    Text(
                      _stripMarkdown(widget.track.title),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Author name
                    if (widget.track.channel != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.track.channel!,
                        style: const TextStyle(
                          color: Color(0xFFB4BEDA),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const Spacer(),
                    // Translucent control panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Progress slider with time indicators
                          if (_controller != null) ...[
                            Row(
                              children: [
                                Text(
                                  _formatDuration(_currentPosition),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      trackHeight: 2,
                                    ),
                                    child: Slider(
                                      value: _totalDuration.inMilliseconds > 0
                                          ? _currentPosition.inMilliseconds.toDouble()
                                          : 0.0,
                                      max: _totalDuration.inMilliseconds > 0
                                          ? _totalDuration.inMilliseconds.toDouble()
                                          : 1.0,
                                      onChanged: (value) {
                                        _seekTo(Duration(milliseconds: value.toInt()));
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(_totalDuration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Control buttons: Rewind, Pause, Fast-forward
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Rewind button
                                _ControlButton(
                                  icon: Icons.replay_10_rounded,
                                  label: '10',
                                  onPressed: _rewind10Seconds,
                                  isDisabled: _isLoading || _error != null,
                                ),
                                const SizedBox(width: 24),
                                // Pause/Play button
                                _PlayPauseButton(
                                  isPlaying: _controller!.value.isPlaying,
                                  isDisabled: _isLoading || _error != null,
                                  onPressed: () {
                                    if (_controller!.value.isPlaying) {
                                      _controller!.pause();
                                    } else {
                                      _controller!.play();
                                    }
                                  },
                                ),
                                const SizedBox(width: 24),
                                // Fast-forward button
                                _ControlButton(
                                  icon: Icons.forward_10_rounded,
                                  label: '10',
                                  onPressed: _fastForward10Seconds,
                                  isDisabled: _isLoading || _error != null,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Audio equalizer
                    _AudioEqualizer(
                      isPlaying: _controller?.value.isPlaying ?? false,
                    ),
                    const SizedBox(height: 16),
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

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isPlaying,
    required this.isDisabled,
    required this.onPressed,
  });

  final bool isPlaying;
  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.white24 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 36,
          color: const Color(0xFF081944),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isDisabled,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Icon(
        icon,
        color: isDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
        size: 28,
      ),
    );
  }
}

class _AudioEqualizer extends StatefulWidget {
  const _AudioEqualizer({required this.isPlaying});

  final bool isPlaying;

  @override
  State<_AudioEqualizer> createState() => _AudioEqualizerState();
}

class _AudioEqualizerState extends State<_AudioEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [0.3, 0.7, 0.5, 0.9, 0.4, 0.6, 0.8, 0.5];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AudioEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              _barHeights.length,
              (index) {
                final baseHeight = _barHeights[index];
                final animatedHeight = widget.isPlaying
                    ? baseHeight +
                        (0.3 * (0.5 - (0.5 - _controller.value).abs()))
                    : baseHeight * 0.3;
                return Container(
                  width: 3,
                  height: 24 * animatedHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
