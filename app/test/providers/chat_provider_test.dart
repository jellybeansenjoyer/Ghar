import 'package:flutter_test/flutter_test.dart';
import 'package:ghar/providers/chat_provider.dart';
import 'package:ghar/models/message.dart';

void main() {
  group('ChatState', () {
    test('should have default values', () {
      final state = ChatState();

      expect(state.messages, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith should update specified fields', () {
      final messages = [
        ChatMessage(
          id: 'm1',
          visitorId: 'v1',
          senderType: 'member',
          senderName: 'Alice',
          content: 'Hello',
          sentAt: DateTime.now(),
        ),
      ];

      final state = ChatState();
      final updated = state.copyWith(messages: messages);

      expect(updated.messages.length, 1);
      expect(updated.messages[0].content, 'Hello');
    });

    test('copyWith should preserve messages when not specified', () {
      final messages = [
        ChatMessage(
          id: 'm1',
          visitorId: 'v1',
          senderType: 'member',
          senderName: 'A',
          content: 'Hi',
          sentAt: DateTime.now(),
        ),
      ];
      final state = ChatState(messages: messages);
      final updated = state.copyWith(isLoading: true);

      expect(updated.messages.length, 1);
      expect(updated.isLoading, true);
    });
  });

  group('ChatNotifier', () {
    late ChatNotifier notifier;

    setUp(() {
      notifier = ChatNotifier();
    });

    test('initial state should have no messages', () {
      expect(notifier.state.messages, isEmpty);
    });

    test('addMessage should add a message from JSON data', () {
      notifier.addMessage({
        'id': 'msg-1',
        'visitorId': 'vis-1',
        'senderType': 'member',
        'senderName': 'Alice',
        'content': 'Hello there!',
        'sentAt': '2025-06-15T10:00:00Z',
      });

      expect(notifier.state.messages.length, 1);
      expect(notifier.state.messages[0].id, 'msg-1');
      expect(notifier.state.messages[0].content, 'Hello there!');
    });

    test('addMessage should not add duplicate messages', () {
      final data = {
        'id': 'msg-dup',
        'visitorId': 'vis-1',
        'senderType': 'visitor',
        'senderName': 'Visitor',
        'content': 'Hi',
        'sentAt': '2025-06-15T10:00:00Z',
      };

      notifier.addMessage(data);
      notifier.addMessage(data); // duplicate

      expect(notifier.state.messages.length, 1);
    });

    test('addMessage should add messages with different IDs', () {
      notifier.addMessage({
        'id': 'msg-1',
        'content': 'First',
        'senderType': 'member',
        'senderName': 'A',
        'sentAt': '2025-06-15T10:00:00Z',
      });
      notifier.addMessage({
        'id': 'msg-2',
        'content': 'Second',
        'senderType': 'visitor',
        'senderName': 'B',
        'sentAt': '2025-06-15T10:01:00Z',
      });

      expect(notifier.state.messages.length, 2);
      expect(notifier.state.messages[0].content, 'First');
      expect(notifier.state.messages[1].content, 'Second');
    });

    test('clear should reset all state', () {
      notifier.addMessage({
        'id': 'msg-1',
        'content': 'Hello',
        'senderType': 'member',
        'senderName': 'A',
        'sentAt': '2025-06-15T10:00:00Z',
      });

      notifier.clear();

      expect(notifier.state.messages, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });
  });
}
