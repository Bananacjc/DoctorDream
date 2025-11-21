import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioService {
  // Singleton
  YoutubeAudioService._();
  static final YoutubeAudioService instance = YoutubeAudioService._();

  final YoutubeExplode _yt = YoutubeExplode();

  /// FAST: Gets the stream URL directly without downloading the file
  Future<String> fetchAudioStreamUrl(String query) async {
    try {
      // 1. Search
      final searchResult = await _yt.search.search(query);
      if (searchResult.isEmpty) throw Exception('No results found');

      final video = searchResult.first;

      // 2. Get Manifest (The list of all file formats)
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      
      // 3. Get the best audio-only stream (M4A is best for mobile)
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // 4. Return the direct URL (This expires in ~1 hour, so don't save it to DB)
      return audioStreamInfo.url.toString();
      
    } catch (e) {
      throw Exception('Failed to get audio URL: $e');
    }
  }

  Future<String?> getThumbnailUrl(String query) async {
    try {
      final searchResult = await _yt.search.search(query);
      if (searchResult.isEmpty) return null;
      // Safe access to thumbnail
      return searchResult.first.thumbnails.highResUrl; 
    } catch (_) {
      return null;
    }
  }
}