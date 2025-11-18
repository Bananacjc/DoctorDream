import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Service responsible for finding audio-only stream URLs on YouTube.
class YoutubeAudioService {
  YoutubeAudioService._() : _yt = YoutubeExplode();

  static final YoutubeAudioService instance = YoutubeAudioService._();
  static const Map<String, String> defaultHttpHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
    'Connection': 'keep-alive',
  };

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

          // Prefer AAC/M4A streams because they are widely supported by Android's
          // native MediaPlayer. Opus/WebM streams (e.g., itag 251) often fail to
          // play and throw MEDIA_ERROR_UNKNOWN(1).
          List<AudioOnlyStreamInfo> pickable = audioStreams
              .where(
                (stream) =>
                    stream.container == StreamContainer.mp4 ||
                    stream.audioCodec.toLowerCase().contains('aac'),
              )
              .toList();

          if (pickable.isEmpty) {
            pickable = audioStreams.toList();
          }

          pickable.sort(
            (a, b) =>
                a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond),
          );

          return pickable.last.url.toString();
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
