import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http; // Requires 'http' package
import 'package:path_provider/path_provider.dart'; // Requires 'path_provider' package

class MusicPlayer {
  MusicPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();
  final AudioPlayer _player;

  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  Future<void> play(String url, {Map<String, String>? headers}) async {
    await _player.stop();

    // 1. Define Headers
    final requestHeaders = headers ??
        {
          'User-Agent':
          'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        };

    try {
      // 2. Download the file manually
      final response = await http.get(Uri.parse(url), headers: requestHeaders);

      if (response.statusCode == 200) {
        // 3. Save to a temporary file
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_audio.mp3');
        await file.writeAsBytes(response.bodyBytes);

        // 4. Play the file
        await _player.play(DeviceFileSource(file.path));
      } else {
        print('Failed to load audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() => _player.resume();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
