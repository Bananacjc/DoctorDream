// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../data/services/gemini_service.dart';
import '../data/models/user_info.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isSending = false;
  bool _hasUserSentMessage = false;

  // User information - can be updated from other screens or user input
  final UserInfo _userInfo = UserInfo.defaultValues();

  static const Color navy = Color(0xFF081944);
  static const Color accent = Color(0xFFB7B9FF);
  static const Color assistantBubbleColor = Color(0xFFE8E8FF);
  static const Color assistantTextColor = Color(0xFF081944);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _messages.add(ChatMessage(text: widget.initialMessage!, isUser: false));
      _hasUserSentMessage = true;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _focusNode.unfocus();
    _textController.clear();

    setState(() {
      _isSending = true;

      if (!_hasUserSentMessage && widget.initialMessage == null) {
        _messages.add(
          ChatMessage(
            text: "Hi, I’m here to listen. What’s on your mind today?",
            isUser: false,
          ),
        );
        _hasUserSentMessage = true;
      }

      _messages.add(ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();

    try {
      final reply = await GeminiService.instance.chat(
        text,
        userInfo: _userInfo,
      );
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    } catch (_) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Sorry, I had trouble responding just now. Could you please try again?",
            isUser: false,
          ),
        );
      });
    } finally {
      _isSending = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        title: const Text(
          'Dream Companion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: navy,
        centerTitle: true,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: (!_hasUserSentMessage && _messages.isEmpty)
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (_, index) =>
                          _buildMessageBubble(_messages[index]),
                    ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DoctorDream is typing...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Show bottom input only AFTER first message
            if (_hasUserSentMessage) _buildTextInput(),
          ],
        ),
      ),
    );
  }

  // -------------------- EMPTY STATE (with centered input bar) --------------------
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Let’s talk to make life happier",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(height: 12),
                Text(
                  "You can tell me about your day,\nyour worries, your dreams,\nor anything that’s on your mind.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Whenever you’re ready,\nstart by typing below.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // CENTERED INPUT BAR (only BEFORE chat begins)
          _buildTextInput(),
        ],
      ),
    );
  }

  // -------------------- INPUT BAR --------------------
  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: navy,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          cursorColor: Colors.white,
          maxLines: null,
          minLines: 1,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendMessage(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Share with DoctorDream...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _textController.text.isNotEmpty ? accent : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _textController.text.isNotEmpty
                      ? _sendMessage
                      : null,
                ),
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  // -------------------- CHAT BUBBLE --------------------
  Widget _buildMessageBubble(ChatMessage message) {
    final bubbleColor = message.isUser ? accent : assistantBubbleColor;
    final textColor = message.isUser ? Colors.white : assistantTextColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
