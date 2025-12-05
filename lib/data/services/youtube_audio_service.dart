import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeAudioService {
  // Singleton pattern
  YoutubeAudioService._() : _yt = YoutubeExplode();
  static final YoutubeAudioService instance = YoutubeAudioService._();

  final YoutubeExplode _yt;

  // AUDIO ONLY METHODS
  // -----------------------------------------------------------------------------

  /// Fetch audio stream URL directly by video ID
  /// This is more reliable than searching, as it uses the exact video ID
  Future<String> fetchAudioStreamUrlById(String videoId) async {
    print('\n========== YOUTUBE AUDIO SERVICE DEBUG (BY ID) ==========');
    print('Video ID: "$videoId"');
    print('YouTube URL: https://www.youtube.com/watch?v=$videoId');

    try {
      final cleanId = videoId.trim();
      final videoIdObj = VideoId(cleanId);

      print('Step 1: Fetching stream manifest...');
      final manifest = await _yt.videos.streamsClient.getManifest(videoIdObj);
      final allAudioStreams = manifest.audioOnly;

      if (allAudioStreams.isEmpty) {
        throw Exception('No audio streams found for video $videoId.');
      }

      print('Step 2: Found ${allAudioStreams.length} audio-only streams');

      // Prefer MP4 container (AAC) if available for maximum compatibility
      final mp4AudioStreams =
          allAudioStreams.where((s) => s.container.name.toLowerCase() == 'mp4');

      var bestStream = mp4AudioStreams.isNotEmpty
          ? mp4AudioStreams.withHighestBitrate()
          : allAudioStreams.withHighestBitrate();

      print('Step 3: Selecting stream ${bestStream.tag}');
      print('  Container: ${bestStream.container.name}');
      print('  Bitrate: ${bestStream.bitrate.bitsPerSecond}');

      final url = bestStream.url.toString();
      print('✓ Successfully generated audio stream URL');
      print('Stream URL: $url');
      return url;
    } catch (e, stackTrace) {
      print('✗ Failed to fetch audio URL by ID');
      print('Error: $e');
      print(stackTrace);
      rethrow;
    } finally {
      print('===============================================\n');
    }
  }

  /// Fetch audio stream URL by search query (searches first, then gets stream)
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
      print('YouTube URL: https://www.youtube.com/watch?v=${video.id.value}');

      // Use the video ID to fetch stream directly (more reliable)
      print('Step 2: Fetching stream by video ID...');
      return await fetchAudioStreamUrlById(video.id.value);
    } catch (e, stackTrace) {
      print('✗ Failed to fetch audio URL');
      print('Error: $e');
      print(stackTrace);
      rethrow;
    } finally {
      print('===============================================\n');
    }
  }

  // VIDEO METHODS
  // -----------------------------------------------------------------------------

  /// Get thumbnail URL from a search query
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

  /// Get video details (ID, URL, thumbnail) from a search query
  Future<Map<String, String?>> getVideoDetails(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      if (searchResults.isNotEmpty) {
        final video = searchResults.first;
        return {
          'videoId': video.id.value,
          'videoUrl': 'https://www.youtube.com/watch?v=${video.id.value}',
          'thumbnailUrl': video.thumbnails.maxResUrl,
          'channel': video.author,
          'title': video.title,
        };
      }
    } catch (e) {
      print('Video details lookup failed: $e');
    }
    return {};
  }

  /// Fetch video stream URL by ID (Used by VideoPlayerScreen)
  Future<String> fetchVideoStreamUrlById(String videoId) async {
    print('\n========== YOUTUBE VIDEO SERVICE DEBUG ==========');
    print('Video ID: "$videoId"');

    try {
      final cleanId = videoId.trim();
      final videoIdObj = VideoId(cleanId);

      print('Step 1: Fetching stream manifest...');
      final manifest = await _yt.videos.streamsClient.getManifest(videoIdObj);

      // We prioritize "Muxed" (Video + Audio) streams for video_player
      final muxedStreams = manifest.muxed;
      print('Step 2: Found ${muxedStreams.length} muxed streams');

      if (muxedStreams.isEmpty) {
        throw Exception('No playable video+audio streams found (Muxed list empty).');
      }

      // Filter for MP4 only as it is the most compatible with Android MediaCodec
      final mp4Streams = muxedStreams
          .where((s) => s.container.name.toLowerCase() == 'mp4')
          .toList();

      final candidates = mp4Streams.isNotEmpty ? mp4Streams : muxedStreams;
      print('Step 3: Filtering candidates (Found ${candidates.length} MP4/Compatible streams)');

      // Select the best stream:
      // 1. Prefer 360p or 480p (Most reliable on mobile/emulators)
      // 2. Sort by bitrate to get decent quality within that resolution
      MuxedStreamInfo? selectedStream;

      // Sort candidates by quality (Resolution) then Bitrate
      final sortedCandidates = candidates.toList()
        ..sort((a, b) => a.videoQuality.index.compareTo(b.videoQuality.index));

      // Try to find exact 360p (safest)
      try {
        selectedStream = sortedCandidates.firstWhere(
                (s) => s.videoQuality.toString().contains('360'));
        print('Selected optimal 360p stream');
      } catch (_) {
        // Fallback: Just take the first one (lowest quality usually, safest for decoding)
        selectedStream = sortedCandidates.first;
        print('Fallback to first available stream: ${selectedStream.videoQuality}');
      }

      print('Step 4: Stream Selected');
      print('  Quality: ${selectedStream.videoQuality}');
      print('  Container: ${selectedStream.container.name}');
      print('  Codec: ${selectedStream.videoCodec}');

      final url = selectedStream.url.toString();
      print('✓ URL Generated');
      return url;

    } catch (e, stackTrace) {
      print('✗ Failed to fetch video URL');
      print('Error: $e');
      print(stackTrace);
      rethrow;
    } finally {
      print('===============================================\n');
    }
  }

  /// Search and fetch video stream URL
  Future<String> fetchVideoStreamUrl(String query) async {
    print('\n========== YOUTUBE SEARCH & PLAY DEBUG ==========');
    try {
      print('Searching for: $query');
      var searchResults = await _yt.search.search(query);

      if (searchResults.isEmpty) {
        // Relaxed search fallback
        final relaxed = _buildRelaxedQuery(query);
        if (relaxed != null) {
          searchResults = await _yt.search.search(relaxed);
        }
      }

      if (searchResults.isEmpty) {
        throw Exception('No video results found.');
      }

      final video = searchResults.first;
      print('Found: ${video.title} [${video.id}]');

      // Redirect to the ID fetcher to keep logic consistent
      return await fetchVideoStreamUrlById(video.id.value);
    } catch (e) {
      print('Search error: $e');
      rethrow;
    }
  }

  String? _buildRelaxedQuery(String raw) {
    var query = raw.replaceAll('"', '').trim();
    for (final sep in ['|', '-', '–', '—', ':']) {
      if (query.contains(sep)) {
        query = query.split(sep).first.trim();
      }
    }
    return query.isEmpty ? null : query;
  }

  void dispose() {
    _yt.close();
  }
}