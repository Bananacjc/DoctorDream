// lib/services/gemini_service.dart

import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/article_recommendation.dart';
import '../models/dream_entry.dart';
import '../models/user_info.dart';
import 'gemini_prompts.dart';

class GeminiService {
  // Singleton instance
  GeminiService._internal()
    : _apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
      _modelName = 'gemini-2.5-flash';

  static final GeminiService instance = GeminiService._internal();

  final String _apiKey;
  final String _modelName;

  // Chat session for maintaining conversation context
  ChatSession? _chatSession;
  UserInfo? _currentChatUserInfo;

  /// Gets a model with a specific system instruction
  GenerativeModel _getModelWithPrompt(String systemPrompt) {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  // Dream analysis prompt
  Future<String> analyzeDream(
    String title,
    String content, {
    UserInfo? userInfo,
  }) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();

      final systemPrompt = GeminiPrompts.buildDreamAnalysisPrompt();

      final model = _getModelWithPrompt(systemPrompt);

      final userMessage = "Dream Title: $title\n\nDream Content: $content";

      final response = await model.generateContent([Content.text(userMessage)]);

      final reply = response.text?.trim();

      return reply?.isNotEmpty == true
          ? reply!
          : "Could not analyze the dream "
                "at "
                "this time. Please try again later.";
    } catch (e) {
      print("GEMINI API ERROR (analyzeDream): $e");
      return "Sorry, I had trouble analyzing the dream. Please try again "
          "later.";
    }
  }

  // Dream Diagnosis Prompt
  Future<String> diagnoseDream(
    List<DreamEntry> dreams, {
    UserInfo? userInfo,
  }) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();

      final systemPrompt = GeminiPrompts.buildDreamDiagnosisPrompt();

      final model = _getModelWithPrompt(systemPrompt);

      final dreamList = StringBuffer();
      for (int i = 0; i < dreams.length; i++) {
        dreamList.writeln('Dream ${i + 1}');
        dreamList.writeln('Title: ${dreams[i].dreamTitle}');
        dreamList.writeln('Content: ${dreams[i].dreamContent}');
      }

      final response = await model.generateContent([
        Content.text(dreamList.toString()),
      ]);

      final reply = response.text?.trim();

      return reply?.isNotEmpty == true
          ? reply!
          : "Could not diagnose the "
                "dreams at this time. Please try again later.";
    } catch (e) {
      print("GEMINI API ERROR (diagnoseDream): $e");
      return "Sorry, I had trouble diagnosing the dream. Please try again "
          "later.";
    }
  }

  /// Starts or resets chat session with user info
  void _initializeChatSession(UserInfo userInfo) {
    // If user info changed, reset the session
    if (_currentChatUserInfo != userInfo) {
      final prompt = GeminiPrompts.buildChatPrompt(userInfo);
      final model = _getModelWithPrompt(prompt);
      _chatSession = model.startChat();
      _currentChatUserInfo = userInfo;
    }
  }

  /// General chat conversation (maintains context)
  Future<String> chat(String userMessage, {UserInfo? userInfo}) async {
    if (userMessage.trim().isEmpty) return '';

    try {
      // Use default user info if not provided
      final info = userInfo ?? UserInfo.defaultValues();
      _initializeChatSession(info);

      // We use _chatSession.sendMessage to maintain context
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage.trim()),
      );

      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No response from Gemini)';
    } catch (e) {
      print('Gemini API error: $e');
      return 'Sorry, I had trouble responding just now. Could you please try again?';
    }
  }

  /// Recommends YouTube videos based on user information
  Future<String> recommendVideo({
    UserInfo? userInfo,
    String? additionalContext,
  }) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildVideoRecommendationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final requestText = additionalContext?.isNotEmpty == true
          ? 'Please recommend YouTube videos. Context: $additionalContext'
          : 'Please recommend YouTube videos that would be helpful for me.';

      final response = await model.generateContent([Content.text(requestText)]);
      final reply = response.text?.trim();
      return reply?.isNotEmpty == true
          ? reply!
          : '(No video recommendations available)';
    } catch (e) {
      print('Gemini API error (recommendVideo): $e');
      return 'Sorry, I had trouble generating video recommendations. Could you please try again?';
    }
  }

  /// Recommends Spotify songs/playlists based on user information
  Future<String> recommendMusic({
    UserInfo? userInfo,
    String? additionalContext,
  }) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildMusicRecommendationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final requestText = additionalContext?.isNotEmpty == true
          ? 'Please recommend Spotify songs or playlists. Context: $additionalContext'
          : 'Please recommend Spotify songs or playlists that would be helpful for me.';

      final response = await model.generateContent([Content.text(requestText)]);
      final reply = response.text?.trim();
      return reply?.isNotEmpty == true
          ? reply!
          : '(No music recommendations available)';
    } catch (e) {
      print('Gemini API error (recommendMusic): $e');
      return 'Sorry, I had trouble generating music recommendations. Could you please try again?';
    }
  }

  /// Generates a helpful article based on user information
  Future<String> generateArticle({UserInfo? userInfo, String? topic}) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildArticleGenerationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final requestText = topic?.isNotEmpty == true
          ? 'Please generate a helpful article about: $topic'
          : 'Please generate a helpful article that would be beneficial for me.';

      final response = await model.generateContent([Content.text(requestText)]);
      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No article generated)';
    } catch (e) {
      print('Gemini API error (generateArticle): $e');
      return 'Sorry, I had trouble generating the article. Could you please try again?';
    }
  }

  /// Generates multiple article recommendations formatted as structured data
  Future<List<ArticleRecommendation>> recommendArticles({
    UserInfo? userInfo,
    int count = 4,
    String? personalizationPrompt,
  }) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildArticleGenerationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final extraContext = (personalizationPrompt?.trim().isNotEmpty ?? false)
          ? 'User request/context: "${personalizationPrompt!.trim()}". '
                'Reflect this specifically in each article.'
          : '';

      final request =
          '''
Create $count concise article recommendations tailored to the user. 
Return valid JSON ONLY (no backticks, no commentary) matching this schema:
{
  "articles": [
    {
      "title": "short title",
      "summary": "2 sentence overview",
      "content": "400-600 word article body with headings",
      "moodBenefit": "why this helps the user",
      "tags": ["keyword1", "keyword2"]
    }
  ]
}
Ensure the JSON parses without modification.
$extraContext
''';

      final response = await model.generateContent([Content.text(request)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return const [];

      final jsonString = _extractJsonObject(text);
      if (jsonString == null) return const [];

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final articles = decoded['articles'];
      if (articles is! List) return const [];

      return articles
          .whereType<Map<String, dynamic>>()
          .map(ArticleRecommendation.fromMap)
          .toList();
    } catch (e) {
      print('Gemini API error (recommendArticles): $e');
      return const [];
    }
  }

  String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }
}
