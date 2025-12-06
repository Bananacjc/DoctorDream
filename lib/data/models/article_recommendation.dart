class ArticleRecommendation {
  const ArticleRecommendation({
    required this.title,
    required this.summary,
    required this.content,
    this.moodBenefit,
    this.tags = const [],
    this.savedAt,
  });

  final String title;
  final String summary;
  final String content;
  final String? moodBenefit;
  final List<String> tags;
  final DateTime? savedAt;

  ArticleRecommendation copyWith({
    String? title,
    String? summary,
    String? content,
    String? moodBenefit,
    List<String>? tags,
    DateTime? savedAt,
  }) {
    return ArticleRecommendation(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      moodBenefit: moodBenefit ?? this.moodBenefit,
      tags: tags ?? this.tags,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  factory ArticleRecommendation.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];
    return ArticleRecommendation(
      title: (map['title'] as String? ?? '').trim(),
      summary: (map['summary'] as String? ?? '').trim(),
      content: (map['content'] as String? ?? '').trim(),
      moodBenefit: (map['moodBenefit'] as String?)?.trim(),
      tags: rawTags is List
          ? rawTags.whereType<String>().map((e) => e.trim()).toList()
          : const [],
      savedAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at'] as String) 
          : (map['savedAt'] != null 
              ? DateTime.tryParse(map['savedAt'] as String) 
              : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      if (moodBenefit != null) 'moodBenefit': moodBenefit,
      if (tags.isNotEmpty) 'tags': tags,
      if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    };
  }
}
