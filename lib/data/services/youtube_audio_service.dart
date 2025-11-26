// ignore_for_file: avoid_print

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioService {
  YoutubeAudioService._() : _yt = YoutubeExplode();

  static final YoutubeAudioService instance = YoutubeAudioService._();

  final YoutubeExplode _yt;

  Future<String> fetchAudioStreamUrl(String query) async {
    print('\n========== YOUTUBE AUDIO SERVICE DEBUG ==========');
    print('Query: "$query"');

    try {
      print('Step 1: Searching YouTube...');
      final searchResults = await _yt.search.search(query);
      if (searchResults.isEmpty) {
        throw Exception('No video results found for query.');
      }
      final video = searchResults.first;

      print('Search returned ${searchResults.length} results');
      print('Selected video: ${video.title} (${video.id.value})');

      print('Step 2: Fetching stream manifest...');
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        throw Exception('No audio streams found for video ${video.id.value}.');
      }

      print('Step 3: Found ${audioStreams.length} audio-only streams');
      AudioOnlyStreamInfo? bestStream;
      for (final stream in audioStreams) {
        final codec = stream.audioCodec;
        final bitrate = stream.bitrate.bitsPerSecond;
        final container = stream.container.name.toUpperCase();
        print('  - Stream ${stream.tag}: $container | $codec | $bitrate bps');
        if (bestStream == null ||
            stream.bitrate.bitsPerSecond > bestStream.bitrate.bitsPerSecond) {
          bestStream = stream;
        }
      }

      final selected = bestStream!;
      print('Step 4: Selecting stream ${selected.tag}');
      print('  Container: ${selected.container.name}');
      print('  Bitrate: ${selected.bitrate.bitsPerSecond}');

      final url = selected.url.toString();
      print('✓ Successfully generated audio stream URL');
      final previewLength = url.length < 64 ? url.length : 64;
      print('URL preview: ${url.substring(0, previewLength)}...');

      return url;
    } catch (e, stackTrace) {
      print('✗ Failed to fetch audio URL');
      print('Error: $e');
      print('Stack trace:');
      print(stackTrace);
      rethrow;
    } finally {
      print('===============================================\n');
    }
  }

  Future<String?> getThumbnailUrl(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      if (searchResults.isNotEmpty) {
        return searchResults.first.thumbnails.maxResUrl;
      }
    } catch (e) {
      print('Thumbnail lookup failed: $e');
    }
    return null;
  }

  void dispose() {
    _yt.close();
  }
}
