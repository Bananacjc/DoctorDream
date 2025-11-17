import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Service responsible for finding audio-only stream URLs on YouTube.
class YoutubeAudioService {
  YoutubeAudioService._() : _yt = YoutubeExplode();

  static final YoutubeAudioService instance = YoutubeAudioService._();

  final YoutubeExplode _yt;

  /// Gets the thumbnail URL for the first YouTube search result matching [query].
  Future<String?> getThumbnailUrl(String query) async {
    try {
      final searchResult = await _yt.search.search(query);
      if (searchResult.isEmpty) {
        return null;
      }
      final video = searchResult.first;
      // Use standard YouTube thumbnail URL pattern
      // Try maxresdefault first (highest quality), fallback to hqdefault
      final videoId = video.id.value;
      return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
    } catch (_) {
      return null;
    }
  }

  /// Searches YouTube for the best audio-only stream that matches [query].
  ///
  /// Tries multiple search results until a playable stream is found in order
  /// to avoid failures on region-locked or age-restricted videos.
  Future<String> fetchBestAudioStreamUrl(String query) async {
    try {
      final searchResult = await _yt.search.search(query);

      if (searchResult.isEmpty) {
        throw Exception('No YouTube results found for "$query".');
      }

      final candidates = searchResult.take(6);

      for (final video in candidates) {
        try {
          final manifest = await _yt.videos.streamsClient.getManifest(video.id);
          final audioStreams = manifest.audioOnly;

          if (audioStreams.isEmpty) {
            continue;
          }

          final sortedStreams = audioStreams.toList()
            ..sort(
              (a, b) =>
                  a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond),
            );

          return sortedStreams.last.url.toString();
        } catch (_) {
          // Try next candidate.
          continue;
        }
      }

      throw Exception('No playable audio streams found for "$query".');
    } catch (error) {
      throw Exception('Failed to load audio from YouTube: $error');
    }
  }

  void dispose() {
    _yt.close();
  }
}
