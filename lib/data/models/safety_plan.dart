class SafetyPlan {
  const SafetyPlan({
    this.id,
    required this.title,
    required this.steps,
    this.createdAt,
  });

  final int? id;
  final String title;
  final List<String> steps;
  final DateTime? createdAt;

  SafetyPlan copyWith({
    int? id,
    String? title,
    List<String>? steps,
    DateTime? createdAt,
  }) {
    return SafetyPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      steps: steps ?? List<String>.from(this.steps),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory SafetyPlan.fromMap(Map<String, dynamic> map, List<String> steps) {
    return SafetyPlan(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      createdAt: map['created_at'] != null && map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      steps: steps,
    );
  }
}


