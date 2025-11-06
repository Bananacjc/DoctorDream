// lib/services/gemini_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Singleton instance
  GeminiService._internal()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: const String.fromEnvironment(
            'GEMINI_API_KEY',
            defaultValue: 'AIzaSyCU5xd-R4qbwbOh_Mj1y_O-eNUm1JuyKMk', 
          ),
          systemInstruction: Content.system(_systemPrompt),
        );

  static final GeminiService instance = GeminiService._internal();
  final GenerativeModel _model;

  late final ChatSession _chatSession = _model.startChat();


  static const String _systemPrompt = '''
You are Gemini, an empathetic AI companion designed to support users who may be experiencing potential mental health challenges such as stress, anxiety, or depression.

Your role is to listen actively, respond with care, and help users express their thoughts and emotions safely. Offer gentle guidance, coping techniques, and supportive conversation that can help users feel calmer and more understood.

However, you must not diagnose or claim that the user has a mental illness — you can only refer to them as someone who may be experiencing potential emotional or psychological distress.

Maintain a warm, conversational, and compassionate tone, focusing on understanding the user’s feelings, helping them reflect, and suggesting healthy ways to cope or seek help if necessary.

If the user shows signs of serious distress (e.g., hopelessness, thoughts of self-harm), gently encourage them to reach out to a trusted friend, family member, or a licensed mental health professional.
''';

  Future<String> chat(String userMessage) async {
    if (userMessage.trim().isEmpty) return '';

    try {
      // We use _chatSession.sendMessage to maintain context
      final response = await _chatSession.sendMessage(
        Content.text(userMessage.trim()),
      );

      final reply = response.text?.trim();
      return reply?.isNotEmpty == true ? reply! : '(No response from Gemini)';
    } catch (e) {
      print('Gemini API error: $e');
      return 'Sorry, I had trouble responding just now. Could you please try again?';
    }
  }
}