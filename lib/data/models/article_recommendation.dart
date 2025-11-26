class ArticleRecommendation {
  const ArticleRecommendation({
    required this.title,
    required this.summary,
    required this.content,
    this.moodBenefit,
    this.tags = const [],
  });

  final String title;
  final String summary;
  final String content;
  final String? moodBenefit;
  final List<String> tags;

  ArticleRecommendation copyWith({
    String? title,
    String? summary,
    String? content,
    String? moodBenefit,
    List<String>? tags,
  }) {
    return ArticleRecommendation(
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      moodBenefit: moodBenefit ?? this.moodBenefit,
      tags: tags ?? this.tags,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      if (moodBenefit != null) 'moodBenefit': moodBenefit,
      if (tags.isNotEmpty) 'tags': tags,
    };
  }
}
