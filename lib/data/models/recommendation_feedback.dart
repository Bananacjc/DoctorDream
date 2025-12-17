class RecommendationFeedback {
  final int? id;
  final String recommendationId;
  final String type; // 'music' or 'video'
  final int rating;
  final String? comment;
  final String relatedDreamId;
  final DateTime timestamp;

  RecommendationFeedback({
    this.id,
    required this.recommendationId,
    required this.type,
    required this.rating,
    this.comment,
    required this.relatedDreamId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recommendation_id': recommendationId,
      'type': type,
      'rating': rating,
      'comment': comment,
      'related_dream_id': relatedDreamId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RecommendationFeedback.fromMap(Map<String, dynamic> map) {
    return RecommendationFeedback(
      id: map['id'] as int?,
      recommendationId: map['recommendation_id'] as String,
      type: map['type'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      relatedDreamId: map['related_dream_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

