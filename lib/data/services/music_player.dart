import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  MusicPlayer() {
    _configureSession();
  }

  final AudioPlayer _player = AudioPlayer();

  // Expose the core streams the UI needs.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Optional direct access if you ever need lower-level control.
  AudioPlayer get rawPlayer => _player;

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      // Safe to keep as a print – this only affects audio focus / ducking.
      print('AudioSession configuration failed: $e');
    }
  }

  Future<void> playUrl(String url) async {
    print('\n========== MUSIC PLAYER DEBUG ==========');
    print('Attempting to play URL');
    print('URL: $url');

    try {
      // Stop any existing playback first.
      if (_player.playing) {
        await _player.stop();
        await _player.seek(Duration.zero);
        print('Previous playback stopped');
      }

      // IMPORTANT: YouTube 403 fix – use headers + AudioSource.uri, NOT setUrl()
      final headers = <String, String>{
        // Use a realistic Android / YouTube-y User-Agent
        'User-Agent':
        'com.google.android.youtube/19.20.33 (Linux; U; Android 12; en_US) gzip',

        // Make the request look like it comes from a YouTube page
        'Referer': 'https://www.youtube.com/',
        'Origin': 'https://www.youtube.com',

        // Optional but safe
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'identity',
      };

      final audioSource = AudioSource.uri(
        Uri.parse(url),
        headers: headers,
      );

      print('Loading URL with setAudioSource() + headers...');
      final duration = await _player.setAudioSource(audioSource);
      print('Audio source loaded. Reported duration: $duration');

      print('Starting playback with play()...');
      await _player.play();
      print('✓ Playback started successfully!');
    } on PlayerException catch (e, stackTrace) {
      // just_audio specific error
      print('✗ PlayerException while starting playback');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print(stackTrace);
      rethrow;
    } on PlayerInterruptedException catch (e, stackTrace) {
      // Loading was interrupted by another load/stop/dispose
      print('✗ PlayerInterruptedException while starting playback');
      print('Message: ${e.message}');
      print(stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      // Any other unexpected error
      print('✗ Unknown error while starting playback');
      print('Error: $e');
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
    // In just_audio, resume is just calling play() again.
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Adjust playback speed (1.0 = normal).
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  /// Adjust volume (0.0 = silent, 1.0 = full).
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}
