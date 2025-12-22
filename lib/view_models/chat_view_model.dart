import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/local/local_database.dart';
import '../data/models/user_info.dart';
import '../data/models/chat_session.dart';
import '../data/models/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({LocalDatabase? database})
      : _database = database ?? LocalDatabase.instance;

  final LocalDatabase _database;

  // User information
  UserInfo _userInfo = UserInfo.defaultValues();
  UserInfo get userInfo => _userInfo;

  // Chat sessions
  List<ChatSession> _sessions = [];
  List<ChatSession> get sessions => _sessions;

  // Current session messages
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  /// Load user profile and convert to UserInfo
  Future<void> loadUserProfile() async {
    try {
      final profile = await _database.fetchUserProfile();
      _userInfo = UserInfo.fromUserProfile(profile);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userInfo = UserInfo.defaultValues();
      notifyListeners();
    }
  }

  /// Load all chat sessions
  Future<void> loadSessions() async {
    try {
      _sessions = await _database.fetchChatSessions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
      _sessions = [];
      notifyListeners();
    }
  }

  /// Load messages for a specific session
  Future<void> loadSessionMessages(String sessionId) async {
    _isLoadingHistory = true;
    _currentSessionId = sessionId;
    _messages.clear();
    notifyListeners();

    try {
      _messages = await _database.fetchChatMessages(sessionId);
    } catch (e) {
      debugPrint('Error loading session messages: $e');
      _messages = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Create a new chat session
  Future<ChatSession> createSession(String title) async {
    try {
      final newSessionId = const Uuid().v4();
      final now = DateTime.now();
      
      // Truncate title if too long
      String sessionTitle = title;
      if (sessionTitle.length > 30) {
        sessionTitle = '${sessionTitle.substring(0, 30)}...';
      }

      final session = ChatSession(
        id: newSessionId,
        title: sessionTitle,
        createdAt: now,
        updatedAt: now,
      );

      await _database.createChatSession(session);
      
      // Add to local list and set as current
      _sessions.insert(0, session);
      _currentSessionId = newSessionId;
      
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Save a chat message and add to local messages if it's for current session
  Future<void> saveMessage(ChatMessage message) async {
    try {
      await _database.saveChatMessage(message);
      
      // Add to local messages if it's for the current session
      if (message.sessionId == _currentSessionId) {
        _messages.add(message);
        notifyListeners();
      }
      
      // Reload sessions to update the updatedAt timestamp
      await loadSessions();
    } catch (e) {
      debugPrint('Error saving chat message: $e');
      rethrow;
    }
  }

  /// Add a message to the local messages list (for immediate UI update)
  void addMessage(ChatMessage message) {
    if (message.sessionId == _currentSessionId) {
      _messages.add(message);
      notifyListeners();
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _database.deleteChatSession(sessionId);
      
      // If deleted session was current, clear it
      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
        _messages.clear();
      }
      
      // Reload sessions
      await loadSessions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat session: $e');
      rethrow;
    }
  }

  /// Clear current session (start new chat)
  void clearCurrentSession() {
    _currentSessionId = null;
    _messages.clear();
    notifyListeners();
  }

  /// Initialize chat data
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadUserProfile(),
        loadSessions(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

