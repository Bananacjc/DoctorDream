// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:doctor_dream/services/gemini_service.dart'; // Ensure this path is correct

// A simple class to hold our message data
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  // Colors from your design
  static const Color navy = Color(0xFF081944);
  static const Color accent = Color(0xFFB7B9FF);
  // A new color for the assistant's bubble
  static const Color assistantBubbleColor = Color(0xFFE8E8FF);
  static const Color assistantTextColor = Color(0xFF081944);


  @override
  void initState() {
    super.initState();
    // Add the initial greeting from the assistant
    _messages.add(ChatMessage(
      text: "Hi, I’m here to listen. What’s on your mind today?",
      isUser: false,
    ));
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

    _focusNode.unfocus(); // Hide keyboard
    _textController.clear();

    setState(() {
      _isSending = true;
      // Add user's message to the list
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();

    try {
      final reply = await GeminiService.instance.chat(text);
      setState(() {
        // Add assistant's reply to the list
        _messages.add(ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      setState(() {
        // Add error message to the list
        _messages.add(ChatMessage(
          text: "I’m sorry, I couldn’t respond just now. Let's try again.",
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // A small delay ensures the ListView has rebuilt before we scroll
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
          'Chat',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            
            // "Typing" indicator
            if (_isSending)
              const Padding(
                padding: EdgeInsets.all(8.0),
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
                    SizedBox(width: 10),
                    Text(
                      'DoctorDream is typing...',
                      style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              ),

            // Text input field
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  // Widget for the text input bar
  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: navy, // Ensures background is navy
      child: Container(
        constraints: const BoxConstraints(maxHeight: 120),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white,
            width: 1,
          ),
        ),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          cursorColor: Colors.white,
          maxLines: null,
          minLines: 1,
          textInputAction: TextInputAction.send, // Changed to 'send'
          onSubmitted: (value) => _sendMessage(), // Allows sending with keyboard
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Ask DoctorDream',
            hintStyle: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _textController.text.isNotEmpty ? accent : Colors.grey,
                  shape: BoxShape.circle,
                ),
                 child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                   onPressed: _textController.text.isNotEmpty ? () => _sendMessage() : null,
                ),
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {}); // To update the send button's active state
          },
        ),
      ),
    );
  }

  // Widget for a single chat bubble
  Widget _buildMessageBubble(ChatMessage message) {
    // Align user messages to the right, assistant to the left
    final alignment =
        message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    // Different colors for user and assistant
    final bubbleColor = message.isUser ? accent : assistantBubbleColor;
    final textColor = message.isUser ? Colors.white : assistantTextColor;
    
    // Different border radius for a "chat" look
    final borderRadius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              // Max width of the bubble is 75% of the screen
              maxWidth: MediaQuery.of(context).size.width * 0.75, 
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}