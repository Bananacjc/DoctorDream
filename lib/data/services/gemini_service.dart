// lib/services/gemini_service.dart

import 'dart:convert';
import 'dart:developer';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/article_recommendation.dart';
import '../models/dream_entry.dart';
import '../models/dream_diagnosis.dart';
import '../models/user_info.dart';
import 'gemini_prompts.dart';

class GeminiService {
  // Singleton instance
  GeminiService._internal()
    : _apiKey = const String.fromEnvironment('GEMINI_API_KEY'),
      _modelName = 'gemini-2.5-flash-lite';

  static final GeminiService instance = GeminiService._internal();

  final String _apiKey;
  final String _modelName;

  // Chat session for maintaining conversation context
  ChatSession? _chatSession;
  UserInfo? _currentChatUserInfo;
  String? _currentChatContext;

  /// Gets a model with a specific system instruction
  GenerativeModel _getModelWithPrompt(String systemPrompt) {
    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
    );
  }

  /// Detects quota/rate-limit errors from the free tier
  bool _isQuotaOrRateLimitError(Object e) {
    final lower = e.toString().toLowerCase();
    return lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('quota') ||
        lower.contains('resource has been exhausted') ||
        lower.contains('daily limit') ||
        lower.contains('billing') ||
        lower.contains('insufficient') ||
        lower.contains('exceed');
  }

  String _friendlyLimitMessage(String action) {
    return 'We have reached the free Gemini quota while $action. '
        'Please try again later today or upgrade your key.';
  }

  String _cleanJsonResult(String text) {
    String cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '');
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll('```', '');
    }
    return cleaned.trim();
  }

  // Dream analysis prompt
  Future<String> analyzeDream(
    String title,
    String content, {
    UserInfo? userInfo,
  }) async {
    try {
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
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('analyzing your dream');
      }
      return "Sorry, I had trouble analyzing the dream. Please try again "
          "later.";
    }
  }

  // Dream Diagnosis Prompt
  Future<String> diagnoseDream(
    List<DreamEntry> dreams, {
    UserInfo? userInfo,
    String? previousDiagnosis,
  }) async {
    try {
      String? cleanPrevious;
      if (previousDiagnosis != null && previousDiagnosis.isNotEmpty) {
        try {
          final jsonMap = jsonDecode(previousDiagnosis);
          cleanPrevious = jsonMap['content'];
        } catch (_) {
          cleanPrevious = previousDiagnosis;
        }
      }

      final isComparative = cleanPrevious != null;

      final systemPrompt = isComparative
          ? GeminiPrompts.buildComparativeDiagnosisPrompt()
          : GeminiPrompts.buildDreamDiagnosisPrompt();

      final model = _getModelWithPrompt(systemPrompt);

      final contentBuffer = StringBuffer();

      if (isComparative) {
        contentBuffer.writeln('--- Previous Diagnosis Analysis ---');
        contentBuffer.writeln(previousDiagnosis!);
        contentBuffer.writeln('--- New Dreams to Analyze ---');
      }

      for (int i = 0; i < dreams.length; i++) {
        contentBuffer.writeln('Dream ${i + 1}');
        contentBuffer.writeln('Title: ${dreams[i].dreamTitle}');
        contentBuffer.writeln('Content: ${dreams[i].dreamContent}');
      }

      log("DIAGNOSIS PROMPT CONTENT: ${contentBuffer.toString()}");

      final response = await model.generateContent([
        Content.text(contentBuffer.toString()),
      ]);

      final reply = response.text?.trim();

      if (reply?.isNotEmpty == true) {
        return _cleanJsonResult(reply!);
      } else {
        return "Could not diagnose the dreams at this time.";
      }

    } catch (e) {
      print("GEMINI API ERROR (diagnoseDream): $e");
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('running the dream diagnosis');
      }
      return "Sorry, I had trouble diagnosing the dream. Please try again "
          "later.";
    }
  }

  /// Builds context string from latest dream and diagnosis
  String _buildChatContext(DreamEntry? latestDream, DreamDiagnosis? latestDiagnosis) {
    final buffer = StringBuffer();
    
    if (latestDream != null) {
      buffer.writeln('--- Latest Dream Entry ---');
      buffer.writeln('Title: ${latestDream.dreamTitle}');
      buffer.writeln('Content: ${latestDream.dreamContent}');
      buffer.writeln('Date: ${latestDream.createdAt.toIso8601String()}');
      buffer.writeln('');
    }
    
    if (latestDiagnosis != null) {
      buffer.writeln('--- Latest Dream Diagnosis ---');
      // Try to parse JSON and extract summary if available
      try {
        final jsonMap = jsonDecode(latestDiagnosis.diagnosisContent);
        if (jsonMap['summary'] != null) {
          buffer.writeln('Summary: ${jsonMap['summary']}');
        }
        if (jsonMap['content'] != null) {
          buffer.writeln('Content: ${jsonMap['content']}');
        } else {
          buffer.writeln('Content: ${latestDiagnosis.diagnosisContent}');
        }
      } catch (_) {
        // If not JSON, use raw content
        buffer.writeln('Content: ${latestDiagnosis.diagnosisContent}');
      }
      buffer.writeln('Date: ${latestDiagnosis.createdAt.toIso8601String()}');
    }
    
    return buffer.toString().trim();
  }

  /// Starts or resets chat session with user info and context
  void _initializeChatSessionWithContext(UserInfo userInfo, String context) {
    // If user info or context changed, reset the session
    if (_currentChatUserInfo != userInfo || _currentChatContext != context) {
      final prompt = GeminiPrompts.buildChatPrompt(userInfo, context: context);
      final model = _getModelWithPrompt(prompt);
      _chatSession = model.startChat();
      _currentChatUserInfo = userInfo;
      _currentChatContext = context;
    }
  }

  /// General chat conversation (maintains context)
  Future<String> chat(
    String userMessage, {
    UserInfo? userInfo,
    DreamEntry? latestDream,
    DreamDiagnosis? latestDiagnosis,
  }) async {
    if (userMessage.trim().isEmpty) return '';

    try {
      // Use default user info if not provided
      final info = userInfo ?? UserInfo.defaultValues();
      
      // Build context string with dream and diagnosis info
      final contextString = _buildChatContext(latestDream, latestDiagnosis);
      
      // Initialize or update chat session with context
      _initializeChatSessionWithContext(info, contextString);

      // We use _chatSession.sendMessage to maintain context
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage.trim()),
      );

      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No response from Gemini)';
    } catch (e) {
      print('Gemini API error: $e');
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('chatting right now');
      }
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
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('loading video recommendations');
      }
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
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('loading music recommendations');
      }
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
      if (_isQuotaOrRateLimitError(e)) {
        return _friendlyLimitMessage('generating this article');
      }
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
      if (_isQuotaOrRateLimitError(e)) {
        return const [];
      }
      return const [];
    }
  }

  String? _extractJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  Future<String> startDreamAnalysisChat({
    required UserInfo userInfo,
    required String title,
    required String analysis,
  }) async {
    try {
      final systemPrompt = GeminiPrompts.buildDreamAnalysisChatPrompt(
        userInfo,
        title,
        analysis,
      );

      final model = _getModelWithPrompt(systemPrompt);
      final analysisChatSession = model.startChat();

      final response = await analysisChatSession.sendMessage(
        Content.text("Start dream analysis discussion."),
      );

      _chatSession = analysisChatSession;
      _currentChatUserInfo = userInfo;

      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No response from Gemini)';
    } catch (e) {
      return "Sorry, I had trouble starting this topic. Please try again.";
    }
  }

  Future<String> startDreamDiagnosisChat({
    required UserInfo userInfo,
    required String diagnosis,
  }) async {
    try {
      final systemPrompt = GeminiPrompts.buildDreamDiagnosisChatPrompt(
        userInfo,
        diagnosis,
      );

      final model = _getModelWithPrompt(systemPrompt);
      final diagnosisChatSession = model.startChat();

      final response = await diagnosisChatSession.sendMessage(
        Content.text("Start dream diagnosis discussion"),
      );

      _chatSession = diagnosisChatSession;
      _currentChatUserInfo = userInfo;

      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No response from Gemini)';
    } catch (e) {
      return "Sorry, I had trouble starting this topic. Please try again.";
    }
  }
}
