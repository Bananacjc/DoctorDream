// lib/models/user_info.dart

class UserInfo {
  final String? emotion;
  final String? dream;
  final Map<String, dynamic>? additionalInfo;

  const UserInfo({
    this.emotion,
    this.dream,
    this.additionalInfo,
  });

  /// Creates a UserInfo with default/hardcoded values for testing
  factory UserInfo.defaultValues() {
    return const UserInfo(
      emotion: 'sad',
      dream: 'nervous',
    );
  }

  /// Creates a UserInfo from a map
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      emotion: map['emotion'] as String?,
      dream: map['dream'] as String?,
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  /// Converts UserInfo to a map
  Map<String, dynamic> toMap() {
    return {
      'emotion': emotion,
      'dream': dream,
      'additionalInfo': additionalInfo,
    };
  }

  /// Builds a formatted string of user information for prompts
  String toPromptString() {
    final buffer = StringBuffer();
    
    if (emotion != null && emotion!.isNotEmpty) {
      buffer.writeln('Current emotion: $emotion');
    }
    
    if (dream != null && dream!.isNotEmpty) {
      buffer.writeln('Dream state: $dream');
    }
    
    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      buffer.writeln('Additional context:');
      additionalInfo!.forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }
    
    return buffer.toString().trim();
  }
}

