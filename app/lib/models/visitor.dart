class Visitor {
  final String id;
  final String familyId;
  final String name;
  final String? photoUrl;
  final String status; // pending, accepted, rejected, expired
  final String? respondedById;
  final String? respondedByName;
  final DateTime arrivedAt;
  final DateTime? respondedAt;

  Visitor({
    required this.id,
    required this.familyId,
    required this.name,
    this.photoUrl,
    this.status = 'pending',
    this.respondedById,
    this.respondedByName,
    required this.arrivedAt,
    this.respondedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'] ?? '',
      familyId: json['familyId'] ?? json['family_id'] ?? '',
      name: json['name'] ?? '',
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      status: json['status'] ?? 'pending',
      respondedById: json['respondedById'] ?? json['responded_by'],
      respondedByName: json['respondedBy'] is Map
          ? json['respondedBy']['name']
          : json['respondedByName'],
      arrivedAt: json['arrivedAt'] != null
          ? DateTime.parse(json['arrivedAt'])
          : (json['arrived_at'] != null
              ? DateTime.parse(json['arrived_at'])
              : DateTime.now()),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isExpired => status == 'expired';
}
