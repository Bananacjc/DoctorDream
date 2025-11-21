import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/models/music_track.dart';
import '../data/services/music_player.dart';
import '../data/services/youtube_audio_service.dart';

class SongPlayerScreen extends StatefulWidget {
  const SongPlayerScreen({super.key, required this.track});

  final MusicTrack track;

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  late final MusicPlayer _musicPlayer;
  final YoutubeAudioService _youtubeAudioService = YoutubeAudioService.instance;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _musicPlayer = MusicPlayer();
    _listenToPlayer();
    _loadAndPlay();
  }

Future<void> _loadAndPlay() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Build query from track title and artist
    final query = "${widget.track.title} ${widget.track.artist} audio";

    try {
      // 1. Get the URL (Takes ~1 second)
      final url = await _youtubeAudioService.fetchAudioStreamUrl(query);
      
      // 2. Stream it immediately
      await _musicPlayer.playUrl(url);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not play this song. (Region lock or Network)';
        print("Playback error: $e");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Also update your listener, just_audio uses different state names
  void _listenToPlayer() {
    _positionSub = _musicPlayer.positionStream.listen((value) {
      setState(() => _position = value);
    });

    // Note: just_audio duration can be null initially
    _durationSub = _musicPlayer.durationStream.listen((value) {
      if (value != null) setState(() => _duration = value);
    });

    _stateSub = _musicPlayer.playerStateStream.listen((state) {
      final isCompleted = state.processingState == ProcessingState.completed;
      setState(() => _isPlaying = state.playing && !isCompleted);
    });
  }

  Future<void> _togglePlay() async {
    if (_isLoading || _error != null) return;
    if (_isPlaying) {
      await _musicPlayer.pause();
    } else {
      await _musicPlayer.resume();
    }
  }

  Future<void> _seek(double milliseconds) async {
    final newPosition = Duration(milliseconds: milliseconds.round());
    await _musicPlayer.seek(newPosition);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _musicPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMillis = _duration.inMilliseconds > 0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;
    final currentMillis = _position.inMilliseconds
        .clamp(0, _duration.inMilliseconds > 0 ? _duration.inMilliseconds : 1)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF081944),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Now Playing'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AlbumArt(
                      title: widget.track.title,
                      thumbnailUrl: widget.track.thumbnailUrl,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.track.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.track.artist,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (widget.track.note != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.track.note!,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (_isLoading) ...[
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 12),
                      const Text(
                        'Loading audio…',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ] else if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAndPlay,
                        child: const Text('Try Again'),
                      ),
                    ] else ...[
                      Slider(
                        value: currentMillis,
                        min: 0,
                        max: maxMillis,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChanged: (value) {
                          setState(() {
                            _position = Duration(milliseconds: value.round());
                          });
                        },
                        onChangeEnd: _seek,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _PlayPauseButton(
                isPlaying: _isPlaying,
                isDisabled: _isLoading || _error != null,
                onPressed: _togglePlay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.title, this.thumbnailUrl});

  final String title;
  final String? thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 320, maxHeight: 320),
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
      ),
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
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.white24 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 42,
          color: const Color(0xFF081944),
        ),
      ),
    );
  }
}
