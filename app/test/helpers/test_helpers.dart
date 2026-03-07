import 'package:ghar/models/user.dart';
import 'package:ghar/models/family.dart';
import 'package:ghar/models/visitor.dart';
import 'package:ghar/models/message.dart';

/// Creates a test user with sensible defaults
AppUser createTestUser({
  String id = 'user-1',
  String name = 'Test User',
  String? phone = '+1234567890',
  String? email = 'test@example.com',
  String? avatarUrl,
  String? familyId,
  String role = 'member',
}) {
  return AppUser(
    id: id,
    name: name,
    phone: phone,
    email: email,
    avatarUrl: avatarUrl,
    familyId: familyId,
    role: role,
  );
}

/// Creates a test family with sensible defaults
Family createTestFamily({
  String id = 'family-1',
  String name = 'Test Family',
  String? address = '123 Test Street',
  String adminId = 'user-1',
  String? qrCodeData = 'http://localhost:3000/visit/family-1',
  DateTime? createdAt,
}) {
  return Family(
    id: id,
    name: name,
    address: address,
    adminId: adminId,
    qrCodeData: qrCodeData,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
  );
}

/// Creates a test visitor with sensible defaults
Visitor createTestVisitor({
  String id = 'visitor-1',
  String familyId = 'family-1',
  String name = 'Test Visitor',
  String? photoUrl,
  String status = 'pending',
  String? respondedById,
  String? respondedByName,
  DateTime? arrivedAt,
  DateTime? respondedAt,
}) {
  return Visitor(
    id: id,
    familyId: familyId,
    name: name,
    photoUrl: photoUrl,
    status: status,
    respondedById: respondedById,
    respondedByName: respondedByName,
    arrivedAt: arrivedAt ?? DateTime.now(),
    respondedAt: respondedAt,
  );
}

/// Creates a test chat message with sensible defaults
ChatMessage createTestMessage({
  String id = 'msg-1',
  String visitorId = 'visitor-1',
  String senderType = 'member',
  String senderName = 'Test User',
  String? senderId = 'user-1',
  String content = 'Hello!',
  DateTime? sentAt,
}) {
  return ChatMessage(
    id: id,
    visitorId: visitorId,
    senderType: senderType,
    senderName: senderName,
    senderId: senderId,
    content: content,
    sentAt: sentAt ?? DateTime.now(),
  );
}
