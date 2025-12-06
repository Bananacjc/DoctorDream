class MusicTrack {
  const MusicTrack({
    required this.title,
    required this.artist,
    this.note,
    this.thumbnailUrl,
    this.savedAt,
  });

  final String title;
  final String artist;
  final String? note;
  final String? thumbnailUrl;
  final DateTime? savedAt;

  MusicTrack copyWith({
    String? title,
    String? artist,
    String? note,
    String? thumbnailUrl,
    DateTime? savedAt,
  }) {
    return MusicTrack(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      note: note ?? this.note,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      if (note != null) 'note': note,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    };
  }

  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      note: map['note'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      savedAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : (map['savedAt'] != null 
              ? DateTime.tryParse(map['savedAt'] as String) 
              : null),
    );
  }

  /// Builds a consistent search query for YouTube lookups.
  String buildSearchQuery() {
    final cleanedTitle = title.trim();
    final cleanedArtist = artist.trim();
    return '$cleanedTitle $cleanedArtist audio';
  }
}
