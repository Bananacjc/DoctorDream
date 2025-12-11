// lib/models/user_info.dart

class UserInfo {
  final String? name;
  final int? age;
  final Map<String, dynamic>? additionalInfo;

  const UserInfo({
    this.name,
    this.age,
    this.additionalInfo,
  });

  /// Creates a UserInfo with default/hardcoded values for testing
  factory UserInfo.defaultValues() {
    return const UserInfo(
      name: 'Dreamer',
      age: 25,
    );
  }

  /// Creates a UserInfo from a map
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    return UserInfo(
      name: map['name'] as String?,
      age: map['age'] is int ? map['age'] as int? : int.tryParse('${map['age']}'),
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  /// Converts UserInfo to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'additionalInfo': additionalInfo,
    };
  }

  /// Builds a formatted string of user information for prompts
  String toPromptString() {
    final buffer = StringBuffer();
    
    if (name != null && name!.isNotEmpty) {
      buffer.writeln('User name: $name');
    }
    
    if (age != null && age! > 0) {
      buffer.writeln('Age: $age');
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

