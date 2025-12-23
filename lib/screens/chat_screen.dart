// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/gemini_service.dart';
import '../view_models/chat_view_model.dart';
import '../data/models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final bool isAiInitiated;
  final ValueNotifier<int>? activeTabNotifier;

  const ChatScreen({
    super.key,
    this.initialMessage,
    this.isAiInitiated = false,
    this.activeTabNotifier,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // View model for database access
  late final ChatViewModel _viewModel;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isSending = false;
  bool _isActive = true; // Track if chat tab is active

  static const Color navy = Color(0xFF081944);
  static const Color accent = Color(0xFFB7B9FF);
  static const Color assistantBubbleColor = Color(0xFFE8E8FF);
  static const Color assistantTextColor = Color(0xFF081944);

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _viewModel.addListener(_onViewModelChanged);
    // Listen to active tab changes
    widget.activeTabNotifier?.addListener(_onActiveTabChanged);
    _isActive = widget.activeTabNotifier?.value == 3;
    _initChat();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onActiveTabChanged() {
    final wasActive = _isActive;
    _isActive = widget.activeTabNotifier?.value == 3;
    
    if (wasActive && !_isActive) {
      // Tab became inactive - unfocus and close keyboard
      _focusNode.unfocus();
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.activeTabNotifier?.removeListener(_onActiveTabChanged);
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    // Initialize view model (loads user profile and sessions)
    await _viewModel.initialize();

    if (widget.initialMessage != null && widget.isAiInitiated) {
      await _handleIncomingGreeting(widget.initialMessage!);
    } else if (!widget.isAiInitiated) {
      await _startNewSession(withMessage: widget.initialMessage);
    }
  }

  Future<void> _handleIncomingGreeting(String greetingText) async {
    String sessionTitle = "Dream Insight";

    if (greetingText.length > 20) {
      sessionTitle = '${greetingText.substring(0, 20)}...';
    }

    await _createNewSessionIfNeeded(sessionTitle);
    final sessionId = _viewModel.currentSessionId!;

    final assistantMsg = ChatMessage(
      id: const Uuid().v4(),
      sessionId: sessionId,
      text: greetingText,
      isUser: false,
      createdAt: DateTime.now()
    );

    if (mounted) {
      _viewModel.addMessage(assistantMsg);
      _scrollToBottom();

      await _viewModel.saveMessage(assistantMsg);
    }
  }

  Future<void> _loadSessionMessages(String sessionId) async {
    await _viewModel.loadSessionMessages(sessionId);
    if (mounted) {
      _scrollToBottom();
    }
  }

  Future<void> _startNewSession({String? withMessage}) async {
    _viewModel.clearCurrentSession();

    if (withMessage != null) {
      _textController.text = withMessage;
      _sendMessage();
    }
  }

  Future<void> _createNewSessionIfNeeded(String firstMessageText) async {
    if (_viewModel.currentSessionId == null) {
      await _viewModel.createSession(firstMessageText);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending || !_isActive) return;

    _focusNode.unfocus();
    _textController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // 0. Refresh latest dream and diagnosis to ensure we have current context
      await Future.wait([
        _viewModel.loadLatestDream(),
        _viewModel.loadLatestDiagnosis(),
      ]);

      // 1. Ensure session exists
      await _createNewSessionIfNeeded(text);
      final sessionId = _viewModel.currentSessionId!;

      // 2. Create and save user message
      final userMsg = ChatMessage(
        id: const Uuid().v4(),
        sessionId: sessionId,
        text: text,
        isUser: true,
        createdAt: DateTime.now(),
      );

      // Add to UI immediately
      _viewModel.addMessage(userMsg);
      _scrollToBottom();

      // Save to DB
      await _viewModel.saveMessage(userMsg);

      // 3. Get Gemini response (with latest dream and diagnosis context)
      final replyText = await GeminiService.instance.chat(
        text,
        userInfo: _viewModel.userInfo,
        latestDream: _viewModel.latestDream,
        latestDiagnosis: _viewModel.latestDiagnosis,
      );

      // 4. Create and save assistant message
      final assistantMsg = ChatMessage(
        id: const Uuid().v4(),
        sessionId: sessionId,
        text: replyText,
        isUser: false,
        createdAt: DateTime.now(),
      );

      if (mounted) {
        _viewModel.addMessage(assistantMsg);
        await _viewModel.saveMessage(assistantMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        _viewModel.addMessage(
          ChatMessage(
            id: const Uuid().v4(),
            sessionId: _viewModel.currentSessionId ?? '',
            text:
                "Sorry, I had trouble responding just now. Please try again.",
            isUser: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
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
      key: _scaffoldKey,
      extendBodyBehindAppBar: true, // Allow gradient to go behind app bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white),
          tooltip: 'Chat History',
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          'Dream Companion',
          style: GoogleFonts.robotoFlex(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent, // Transparent for gradient
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'New chat',
            onPressed: () => _startNewSession(),
          ),
        ],
      ),
      drawer: _buildHistoryDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF081944), // navy
              Color(0xFF0D2357), // slightly lighter navy
              Color(0xFF152C69), // even lighter
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _viewModel.isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : (_viewModel.messages.isEmpty)
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: _viewModel.messages.length,
                        itemBuilder: (_, index) =>
                            _buildMessageBubble(_viewModel.messages[index]),
                      ),
              ),

              if (_isSending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'DoctorDream is thinking...',
                              style: GoogleFonts.robotoFlex(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              _buildTextInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF081944), // Match app theme
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_edu_rounded,
                      color: accent,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Your Conversations',
                        style: GoogleFonts.robotoFlex(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: accent,
                        size: 28,
                      ),
                      tooltip: 'New Chat',
                      onPressed: () {
                        Navigator.pop(context); // Close drawer
                        _startNewSession();
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _viewModel.sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No chat history yet',
                              style: GoogleFonts.robotoFlex(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _viewModel.sessions.length,
                        itemBuilder: (context, index) {
                          final session = _viewModel.sessions[index];
                          final isSelected = session.id == _viewModel.currentSessionId;

                          return Dismissible(
                            key: Key(session.id),
                            direction: DismissDirection.startToEnd,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              color: Colors.redAccent.withOpacity(0.2),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              // Optional: Add confirmation dialog
                              return true;
                            },
                            onDismissed: (direction) async {
                              await _viewModel.deleteSession(session.id);
                              if (_viewModel.currentSessionId == session.id) {
                                _startNewSession();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(color: accent.withOpacity(0.3))
                                    : null,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? accent
                                      : Colors.white10,
                                  radius: 18,
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 18,
                                    color: isSelected ? navy : Colors.white70,
                                  ),
                                ),
                                title: Text(
                                  session.title,
                                  style: GoogleFonts.robotoFlex(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(session.updatedAt),
                                  style: GoogleFonts.robotoFlex(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context); // Close drawer
                                  _loadSessionMessages(session.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- EMPTY STATE --------------------
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Let's talk to make life happier",
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoFlex(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withOpacity(0.15),
                      accent.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      "I'm here to listen.",
                      style: GoogleFonts.robotoFlex(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Tell me about your day, your worries, your dreams, or just chat.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoFlex(
                        color: Colors.white70,
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- INPUT BAR --------------------
  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background for input area
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: _isActive,
                cursorColor: accent,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: GoogleFonts.robotoFlex(
                  color: _isActive ? Colors.white : Colors.white38,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Share with DoctorDream...',
                  hintStyle: GoogleFonts.robotoFlex(
                    color: _isActive ? Colors.white38 : Colors.white24,
                  ),
                  hintMaxLines: 1,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: (_textController.text.isNotEmpty && _isActive)
                  ? accent
                  : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: (_textController.text.isNotEmpty && _isActive)
                    ? navy
                    : Colors.white38,
                size: 20,
              ),
              onPressed: (_textController.text.isNotEmpty && _isActive)
                  ? _sendMessage
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- CHAT BUBBLE --------------------
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? accent : Colors.white;
    final textColor = isUser ? navy : const Color(0xFF333333);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.white10,
              radius: 16,
              child: Icon(Icons.auto_awesome, size: 16, color: accent),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: GoogleFonts.robotoFlex(
                      color: textColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: GoogleFonts.robotoFlex(
                      color: textColor.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.white10,
              radius: 16,
              child: Icon(Icons.person, size: 16, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
