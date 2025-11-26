class DreamDiagnosis {
  final String diagnosisID;
  final String diagnosisContent;
  final DateTime createdAt;

  DreamDiagnosis({
    required this.diagnosisID,
    required this.diagnosisContent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'diagnosis_id': diagnosisID,
      'diagnosis_content': diagnosisContent,
      'created_at' : createdAt.toIso8601String(),
    };
  }

  factory DreamDiagnosis.fromMap(Map<String, dynamic> map) {
    return DreamDiagnosis(
      diagnosisID: map['diagnosis_id'],
      diagnosisContent: map['diagnosis_content'],
      createdAt: DateTime.parse(map['created_at'])
    );
  }


}
