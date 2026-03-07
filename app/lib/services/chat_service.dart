import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/message.dart';

class ChatService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<ChatMessage>> getMessages(String visitorId) async {
    final response = await _dio.get('/visitors/$visitorId/messages');
    final list = response.data['data'] as List;
    return list.map((m) => ChatMessage.fromJson(m)).toList();
  }

  Future<ChatMessage> sendMessage({
    required String visitorId,
    required String content,
    required String senderType,
    required String senderName,
  }) async {
    final response = await _dio.post('/visitors/$visitorId/messages', data: {
      'content': content,
      'senderType': senderType,
      'senderName': senderName,
    });
    return ChatMessage.fromJson(response.data['data']);
  }
}
