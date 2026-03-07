class Family {
  final String id;
  final String name;
  final String? address;
  final String adminId;
  final String? qrCodeData;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    this.address,
    required this.adminId,
    this.qrCodeData,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      adminId: json['adminId'] ?? json['admin_id'] ?? '',
      qrCodeData: json['qrCodeData'] ?? json['qr_code_data'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'adminId': adminId,
        'qrCodeData': qrCodeData,
      };
}
