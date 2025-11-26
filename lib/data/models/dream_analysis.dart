class DreamAnalysis {
  final String analysisID;
  final String dreamID;
  final String analysisContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  DreamAnalysis({
    required this.analysisID,
    required this.dreamID,
    required this.analysisContent,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'analysis_id': analysisID,
      'dream_id': dreamID,
      'analysis_content': analysisContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DreamAnalysis.fromMap(Map<String, dynamic> map) {
    return DreamAnalysis(
        analysisID: map['analysis_id'],
        dreamID: map['dream_id'],
        analysisContent: map['analysis_content'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  DreamAnalysis copyWith({
    String? analysisID,
    String? dreamID,
    String? analysisContent,
    DateTime? createdAt,
    DateTime? updatedAt,
}) {
    return DreamAnalysis(
      analysisID: analysisID ?? this.analysisID,
      dreamID: dreamID ?? this.dreamID,
      analysisContent:  analysisContent ?? this.analysisContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

}
