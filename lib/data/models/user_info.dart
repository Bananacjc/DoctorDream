// lib/models/user_info.dart

import 'user_profile.dart';

class UserInfo {
  final String? name;
  final int? age;
  final Map<String, dynamic>? additionalInfo;

  const UserInfo({
    this.name,
    this.age,
    this.additionalInfo,
  });

  /// Neutral defaults (no personal data). Real profile should be mapped via [fromUserProfile].
  factory UserInfo.defaultValues() {
    return const UserInfo();
  }

  /// Build UserInfo from a persisted [UserProfile].
  factory UserInfo.fromUserProfile(UserProfile profile) {
    int? computedAge;
    if (profile.birthday.isNotEmpty) {
      final dob = DateTime.tryParse(profile.birthday);
      if (dob != null) {
        final now = DateTime.now();
        var age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        if (age > 0) {
          computedAge = age;
        }
      }
    }

    final extra = <String, dynamic>{};
    if (profile.location.isNotEmpty) {
      extra['Location'] = profile.location;
    }
    if (profile.pronouns.isNotEmpty) {
      extra['Pronouns'] = profile.pronouns;
    }
    if (profile.notes.isNotEmpty) {
      extra['Notes'] = profile.notes;
    }

    return UserInfo(
      name: profile.fullName.isNotEmpty ? profile.fullName : null,
      age: computedAge,
      additionalInfo: extra.isEmpty ? null : extra,
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

