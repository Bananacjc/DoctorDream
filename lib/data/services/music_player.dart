import 'dart:async';
import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  // Singleton pattern to ensure only one player exists
  static final MusicPlayer _instance = MusicPlayer._internal();
  factory MusicPlayer() => _instance;
  MusicPlayer._internal();

  final AudioPlayer _player = AudioPlayer();

  // Expose streams for the UI
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Plays a YouTube URL with the required headers to bypass 403 errors
  Future<void> playUrl(String url) async {
    try {
      // STOP whatever is playing first
      if (_player.playing) await _player.stop();

      // 1. Define the headers that trick YouTube
      final headers = {
        'User-Agent': 'Mozilla/5.0 ...',
        'Referer': 'https://www.youtube.com/',
      };

      // 2. Load the Audio Source with headers
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          // Try REMOVING the headers if playback fails.
          // Often the URL from youtube_explode already contains the necessary signature.
        ),
      );

      // 3. Start Playing
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Failed to start playback: $e');
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() => _player.stop();
  
  void dispose() {
    _player.dispose();
  }
}