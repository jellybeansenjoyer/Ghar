import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService = ChatService();

  ChatNotifier() : super(ChatState());

  Future<void> loadMessages(String visitorId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await _chatService.getMessages(visitorId);
      state = ChatState(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load messages',
      );
    }
  }

  Future<void> sendMessage({
    required String visitorId,
    required String content,
    required String senderName,
  }) async {
    try {
      final message = await _chatService.sendMessage(
        visitorId: visitorId,
        content: content,
        senderType: 'member',
        senderName: senderName,
      );
      state = state.copyWith(
        messages: [...state.messages, message],
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to send message');
    }
  }

  void addMessage(Map<String, dynamic> data) {
    final message = ChatMessage.fromJson(data);
    // Avoid duplicates
    if (state.messages.any((m) => m.id == message.id)) return;
    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  void clear() {
    state = ChatState();
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
