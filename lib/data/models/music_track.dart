class MusicTrack {
  final String title;
  final String artist;
  final String? note;
  final String? thumbnailUrl;

  const MusicTrack({
    required this.title,
    required this.artist,
    this.note,
    this.thumbnailUrl,
  });

  String buildSearchQuery() => '$title $artist audio';

  MusicTrack copyWith({String? thumbnailUrl}) {
    return MusicTrack(
      title: title,
      artist: artist,
      note: note,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
