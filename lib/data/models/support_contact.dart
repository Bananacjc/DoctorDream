class SupportContact {
  const SupportContact({
    this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String relationship;
  final String phone;
  final DateTime? createdAt;

  SupportContact copyWith({
    int? id,
    String? name,
    String? relationship,
    String? phone,
    DateTime? createdAt,
  }) {
    return SupportContact(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory SupportContact.fromMap(Map<String, dynamic> map) {
    return SupportContact(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      createdAt: map['created_at'] != null && map['created_at'] is String
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final buffer = StringBuffer();
    if (first.isNotEmpty) buffer.write(first[0]);
    if (last.isNotEmpty) buffer.write(last[0]);
    return buffer.toString().toUpperCase();
  }
}


