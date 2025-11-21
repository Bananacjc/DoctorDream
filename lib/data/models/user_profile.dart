class UserProfile {
  final int id;
  final String fullName;
  final String pronouns;
  final String birthday;
  final String email;
  final String phone;
  final String location;
  final String notes;
  final DateTime updatedAt;

  UserProfile({
    this.id = 1,
    this.fullName = '',
    this.pronouns = '',
    this.birthday = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.notes = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory UserProfile.empty() => UserProfile();

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int? ?? 1,
      fullName: map['full_name'] as String? ?? '',
      pronouns: map['pronouns'] as String? ?? '',
      birthday: map['birthday'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'pronouns': pronouns,
      'birthday': birthday,
      'email': email,
      'phone': phone,
      'location': location,
      'notes': notes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? fullName,
    String? pronouns,
    String? birthday,
    String? email,
    String? phone,
    String? location,
    String? notes,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      pronouns: pronouns ?? this.pronouns,
      birthday: birthday ?? this.birthday,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
