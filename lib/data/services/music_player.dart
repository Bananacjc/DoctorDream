// ignore_for_file: avoid_print

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  MusicPlayer() {
    _configureSession();
  }

  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      print('AudioSession configuration failed: $e');
    }
  }

  Future<void> playUrl(String url) async {
    print('\n========== MUSIC PLAYER DEBUG ==========');
    print('Attempting to play URL...');
    print('URL length: ${url.length}');

    try {
      await _player.stop();
      print('Player stopped previous playback');

      print('Setting URL...');
      await _player.setUrl(url);
      print('URL set successfully, starting playback...');

      await _player.play();
      print('✓ Playback started successfully!');
    } catch (e, stackTrace) {
      print('✗ Playback failed!');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      rethrow;
    } finally {
      print('========================================\n');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
