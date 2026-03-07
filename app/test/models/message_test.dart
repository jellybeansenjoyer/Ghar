import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/models/message.dart';

void main() {
  group('ChatMessage', () {
    group('fromJson', () {
      test('should create message from complete JSON', () {
        final json = {
          'id': 'msg-1',
          'visitorId': 'vis-1',
          'senderType': 'member',
          'senderName': 'Alice',
          'senderId': 'user-1',
          'content': 'Hello visitor!',
          'sentAt': '2025-06-15T10:05:00Z',
        };

        final message = ChatMessage.fromJson(json);

        expect(message.id, 'msg-1');
        expect(message.visitorId, 'vis-1');
        expect(message.senderType, 'member');
        expect(message.senderName, 'Alice');
        expect(message.senderId, 'user-1');
        expect(message.content, 'Hello visitor!');
        expect(message.sentAt, DateTime.parse('2025-06-15T10:05:00Z'));
      });

      test('should handle messageId key', () {
        final json = {
          'messageId': 'msg-2',
          'visitorId': 'vis-1',
          'senderType': 'visitor',
          'senderName': 'Visitor',
          'content': 'Hi',
          'sentAt': '2025-01-01T00:00:00Z',
        };

        final message = ChatMessage.fromJson(json);
        expect(message.id, 'msg-2');
      });

      test('should handle snake_case keys', () {
        final json = {
          'id': 'msg-3',
          'visitor_id': 'vis-2',
          'sender_type': 'member',
          'sender_name': 'Bob',
          'sender_id': 'user-2',
          'content': 'Hello',
          'sent_at': '2025-06-15T12:00:00Z',
        };

        final message = ChatMessage.fromJson(json);

        expect(message.visitorId, 'vis-2');
        expect(message.senderType, 'member');
        expect(message.senderName, 'Bob');
        expect(message.senderId, 'user-2');
        expect(message.sentAt, DateTime.parse('2025-06-15T12:00:00Z'));
      });

      test('should handle text key for content', () {
        final json = {
          'id': 'msg-4',
          'text': 'Message via text key',
          'sentAt': '2025-01-01T00:00:00Z',
        };

        final message = ChatMessage.fromJson(json);
        expect(message.content, 'Message via text key');
      });

      test('should default to empty strings for missing required fields', () {
        final json = <String, dynamic>{};

        final message = ChatMessage.fromJson(json);

        expect(message.id, '');
        expect(message.visitorId, '');
        expect(message.senderType, '');
        expect(message.senderName, '');
        expect(message.content, '');
        expect(message.sentAt, isNotNull);
      });

      test('should handle null senderId', () {
        final json = {
          'id': 'msg-5',
          'content': 'From visitor',
          'senderType': 'visitor',
          'senderName': 'V',
          'sentAt': '2025-01-01T00:00:00Z',
        };

        final message = ChatMessage.fromJson(json);
        expect(message.senderId, isNull);
      });
    });

    group('computed properties', () {
      test('isFromVisitor returns true for visitor senderType', () {
        final message = ChatMessage(
          id: '1',
          visitorId: 'v1',
          senderType: 'visitor',
          senderName: 'V',
          content: 'Hi',
          sentAt: DateTime.now(),
        );
        expect(message.isFromVisitor, true);
        expect(message.isFromMember, false);
      });

      test('isFromMember returns true for member senderType', () {
        final message = ChatMessage(
          id: '2',
          visitorId: 'v1',
          senderType: 'member',
          senderName: 'M',
          content: 'Hello',
          sentAt: DateTime.now(),
        );
        expect(message.isFromMember, true);
        expect(message.isFromVisitor, false);
      });
    });
  });
}
