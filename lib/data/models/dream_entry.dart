enum DreamEntryStatus { draft, completed }

class DreamEntry {
  final String dreamID;
  String dreamTitle;
  String dreamContent;
  DreamEntryStatus status;
  DateTime createdAt;
  DateTime updatedAt;
  bool isFavourite;

  DreamEntry({
    required this.dreamID,
    required this.dreamTitle,
    required this.dreamContent,
    required this.createdAt,
    required this.updatedAt,
    this.status = DreamEntryStatus.draft,
    this.isFavourite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'dream_id': dreamID,
      'dream_title': dreamTitle,
      'dream_content': dreamContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status.index,
      'is_favourite': isFavourite ? 1 : 0,
    };
  }

  factory DreamEntry.fromMap(Map<String, dynamic> map) {
    return DreamEntry(
      dreamID: map['dream_id'],
      dreamTitle: map['dream_title'],
      dreamContent: map['dream_content'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      status: DreamEntryStatus.values[map['status']],
      isFavourite: map['is_favourite'] == 1,
    );
  }
}
