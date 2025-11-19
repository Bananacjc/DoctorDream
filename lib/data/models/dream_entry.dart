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
}




