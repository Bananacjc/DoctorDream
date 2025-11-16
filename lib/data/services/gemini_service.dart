// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
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
  Future<String> recommendVideo({UserInfo? userInfo, String? additionalContext}) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildVideoRecommendationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final requestText = additionalContext?.isNotEmpty == true
          ? 'Please recommend YouTube videos. Context: $additionalContext'
          : 'Please recommend YouTube videos that would be helpful for me.';

      final response = await model.generateContent([Content.text(requestText)]);
      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No video recommendations available)';
    } catch (e) {
      print('Gemini API error (recommendVideo): $e');
      return 'Sorry, I had trouble generating video recommendations. Could you please try again?';
    }
  }

  /// Recommends Spotify songs/playlists based on user information
  Future<String> recommendMusic({UserInfo? userInfo, String? additionalContext}) async {
    try {
      final info = userInfo ?? UserInfo.defaultValues();
      final prompt = GeminiPrompts.buildMusicRecommendationPrompt(info);
      final model = _getModelWithPrompt(prompt);

      final requestText = additionalContext?.isNotEmpty == true
          ? 'Please recommend Spotify songs or playlists. Context: $additionalContext'
          : 'Please recommend Spotify songs or playlists that would be helpful for me.';

      final response = await model.generateContent([Content.text(requestText)]);
      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No music recommendations available)';
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
}