import 'package:audioplayers/audioplayers.dart';

/// Lightweight wrapper around [AudioPlayer] to keep audio logic isolated.
class MusicPlayer {
  MusicPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  final AudioPlayer _player;

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  Future<void> play(String url) async {
    await _player.stop();
    await _player.setSourceUrl(url);
    await _player.resume();
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
