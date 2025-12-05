 class VideoTrack {
  const VideoTrack({
    required this.title,
    this.channel,
    this.note,
    this.thumbnailUrl,
    this.videoId,
    this.videoUrl,
    this.savedAt,
  });

  final String title;
  final String? channel;
  final String? note;
  final String? thumbnailUrl;
  final String? videoId;
  final String? videoUrl;
  final DateTime? savedAt;

  VideoTrack copyWith({
    String? title,
    String? channel,
    String? note,
    String? thumbnailUrl,
    String? videoId,
    String? videoUrl,
    DateTime? savedAt,
  }) {
    return VideoTrack(
      title: title ?? this.title,
      channel: channel ?? this.channel,
      note: note ?? this.note,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoId: videoId ?? this.videoId,
      videoUrl: videoUrl ?? this.videoUrl,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      if (channel != null) 'channel': channel,
      if (note != null) 'note': note,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (videoId != null) 'videoId': videoId,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    };
  }

  factory VideoTrack.fromMap(Map<String, dynamic> map) {
    return VideoTrack(
      title: map['title'] as String? ?? '',
      channel: map['channel'] as String?,
      note: map['note'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      videoId: map['videoId'] as String?,
      videoUrl: map['videoUrl'] as String?,
      savedAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : (map['savedAt'] != null 
              ? DateTime.tryParse(map['savedAt'] as String) 
              : null),
    );
  }

  /// Strip markdown formatting from text
  static String _stripMarkdown(String text) {
    // Remove markdown links: [text](url) -> text
    text = text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Remove bold/italic markers: **text** or *text* -> text
    text = text.replaceAllMapped(
      RegExp(r'\*{1,2}([^\*]+)\*{1,2}'),
      (match) => match.group(1) ?? '',
    );
    // Remove any remaining markdown formatting
    text = text.replaceAll(RegExp(r'[\[\]()*_`]'), '');
    return text.trim();
  }

  /// Builds a consistent search query for YouTube lookups.
  String buildSearchQuery() {
    final cleanedTitle = _stripMarkdown(title.trim());
    final cleanedChannel = channel != null ? _stripMarkdown(channel!.trim()) : '';
    if (cleanedChannel.isNotEmpty) {
      return '$cleanedTitle $cleanedChannel';
    }
    return cleanedTitle;
  }

  /// Gets the YouTube URL for this video
  String getYouTubeUrl() {
    if (videoUrl != null) {
      return videoUrl!;
    }
    if (videoId != null) {
      return 'https://www.youtube.com/watch?v=$videoId';
    }
    // Fallback: construct URL from search (not ideal but works)
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(buildSearchQuery())}';
  }
}
