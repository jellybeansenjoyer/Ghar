class AppUser {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final String? familyId;
  final String role;
  final String? onesignalPlayerId;

  AppUser({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl,
    this.familyId,
    this.role = 'member',
    this.onesignalPlayerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      familyId: json['familyId'],
      role: json['role'] ?? 'member',
      onesignalPlayerId: json['onesignalPlayerId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'familyId': familyId,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
  bool get hasFamily => familyId != null;
  bool get hasCompletedProfile => name.isNotEmpty;

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? familyId,
    String? role,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
    );
  }
}
