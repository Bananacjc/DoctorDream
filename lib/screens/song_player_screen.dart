import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../data/models/music_track.dart';
import '../data/services/youtube_audio_service.dart';
import '../data/local/local_database.dart';

class SongPlayerScreen extends StatefulWidget {
  const SongPlayerScreen({super.key, required this.track});

  final MusicTrack track;

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

enum _SongViewMode { song, video }

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  YoutubePlayerController? _controller;
  final YoutubeAudioService _youtubeService = YoutubeAudioService.instance;

  bool _isLoading = true;
  String? _error;
  String? _videoId;
  _SongViewMode _viewMode = _SongViewMode.song;
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
    final isSaved = await LocalDatabase.instance.isMusicSaved(widget.track);
    if (mounted) {
      setState(() => _isSaved = isSaved);
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await LocalDatabase.instance.removeMusic(widget.track);
    } else {
      await LocalDatabase.instance.saveMusic(widget.track);
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

  // ... (existing _initializePlayer method) ...

  void _playerListener() {
    if (!mounted || _controller == null) return;
    final playerState = _controller!.value.playerState;

    final position = _controller!.value.position;
    final duration = _controller!.value.metaData.duration;

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _totalDuration = duration;
      });
    }

    if (playerState == PlayerState.unknown) {
      if (_controller!.value.hasError) {
        if (mounted) {
          setState(() {
            _error = 'Song playback error. Please try again.';
          });
        }
      }
    }
  }

  // ... (existing _reloadPlayer method) ...

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

  Future<void> _initializePlayer() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('\n========== SONG PLAYER SCREEN DEBUG ==========');
      print('Track: ${widget.track.title}');
      print('Artist: ${widget.track.artist}');

      final query = widget.track.buildSearchQuery();
      print('Search Query: "$query"');

      final details = await _youtubeService.getVideoDetails(query);
      if (details.isEmpty || details['videoId'] == null) {
        throw Exception('Could not find video ID for: ${widget.track.title}');
      }

      final videoId = (details['videoId'] as String).trim();
      print('Found Video ID: $videoId');

      if (videoId.isEmpty) {
        throw Exception('Invalid video ID');
      }

      if (!mounted) return;

      _videoId = videoId;

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
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

      print('✓ YouTube song player initialized with ID: $videoId');
      print('=============================================\n');
    } catch (e, stackTrace) {
      print('\n========== SONG PLAYER ERROR ==========');
      print('✗ Failed to initialize YouTube player for song');
      print('Track: ${widget.track.title} by ${widget.track.artist}');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      print('=======================================\n');

      if (!mounted) return;
      setState(() {
        String errorMsg = 'Could not play this song. ';

        if (e.toString().contains('Could not find video ID')) {
          errorMsg += 'Song not found on YouTube.';
        } else if (e.toString().contains('Invalid video ID')) {
          errorMsg += 'Invalid video ID.';
        } else {
          errorMsg += 'Try another song.';
        }

        _error = errorMsg;
        _isLoading = false;
      });
    }
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
        _error = 'Failed to reload song. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_playerListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If controller is not ready, show loading or error
    if (_controller == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
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
          child: Center(
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _reloadPlayer,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    )
                  : const SizedBox(),
        ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: false,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF081944),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
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
                // Mode Toggle
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 16),
                  child: SizedBox(
                    width: 200,
                    child: _ModeToggle(
                      mode: _viewMode,
                      onChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                  ),
                ),

                // Media Area (Video or Album Art)
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Always keep the player in the tree
                        // In video mode: visible
                        // In song mode: visible but covered (or opacity 0 if we want to hide it but keep it active)
                        // NOTE: YoutubePlayer needs to be visible/active to play.
                        // Covering it with another widget is fine.
                        player,

                        // Album Art Overlay (Only if song mode)
                        if (_viewMode == _SongViewMode.song)
                          _AlbumArt(
                            title: widget.track.title,
                            thumbnailUrl: widget.track.thumbnailUrl,
                          ),
                      ],
                    ),
                  ),
                ),

                // Controls Section
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
                        // Song Title
                        Text(
                          widget.track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Artist Name
                        Text(
                          widget.track.artist,
                          style: const TextStyle(
                            color: Color(0xFFB4BEDA),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(),

                        // Translucent Control Panel
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              // Progress Slider
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
                                        inactiveTrackColor:
                                            Colors.white.withOpacity(0.3),
                                        thumbColor: Colors.white,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        trackHeight: 2,
                                      ),
                                      child: Slider(
                                        value: _totalDuration.inMilliseconds > 0
                                            ? _currentPosition.inMilliseconds
                                                .toDouble()
                                            : 0.0,
                                        max: _totalDuration.inMilliseconds > 0
                                            ? _totalDuration.inMilliseconds
                                                .toDouble()
                                            : 1.0,
                                        onChanged: (value) {
                                          _seekTo(Duration(
                                              milliseconds: value.toInt()));
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

                              // Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Rewind
                                  _ControlButton(
                                    icon: Icons.replay_10_rounded,
                                    label: '', // No label
                                    onPressed: _rewind10Seconds,
                                    isDisabled: false,
                                  ),
                                  const SizedBox(width: 24),
                                  // Play/Pause
                                  _PlayPauseButton(
                                    isPlaying: _controller!.value.isPlaying,
                                    isDisabled: false,
                                    onPressed: () {
                                      if (_controller!.value.isPlaying) {
                                        _controller!.pause();
                                      } else {
                                        _controller!.play();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 24),
                                  // Fast Forward
                                  _ControlButton(
                                    icon: Icons.forward_10_rounded,
                                    label: '', // No label
                                    onPressed: _fastForward10Seconds,
                                    isDisabled: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Equalizer
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
      },
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
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

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.title, this.thumbnailUrl});

  final String title;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5563E6), Color(0xFF1F265C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: thumbnailUrl != null
          ? Image.network(
              thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _Placeholder(letter: letter),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _Placeholder(letter: letter);
              },
            )
          : _Placeholder(letter: letter),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String letter;

  const _Placeholder({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.bold,
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  final _SongViewMode mode;
  final ValueChanged<_SongViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(_SongViewMode.song),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mode == _SongViewMode.song
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 18,
                      color: mode == _SongViewMode.song
                          ? const Color(0xFF081944)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Song',
                      style: TextStyle(
                        color: mode == _SongViewMode.song
                            ? const Color(0xFF081944)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(_SongViewMode.video),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: mode == _SongViewMode.video
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      size: 18,
                      color: mode == _SongViewMode.video
                          ? const Color(0xFF081944)
                          : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: mode == _SongViewMode.video
                            ? const Color(0xFF081944)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
