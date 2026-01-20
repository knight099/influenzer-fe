
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(ref.watch(dioProvider));
}

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  /// GET /conversations - List all conversations for the user
  Future<List<dynamic>> listConversations() async {
    final response = await _dio.get('/conversations');
    return (response.data as List<dynamic>?) ?? [];
  }

  /// GET /conversations/:id/messages - Get message history
  Future<List<dynamic>> getMessages(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    return (response.data as List<dynamic>?) ?? [];
  }

  /// POST /conversations/:id/messages - Send a message
  Future<Map<String, dynamic>> sendMessage(
    String conversationId, 
    String text, 
    {String? attachmentUrl}
  ) async {
    final response = await _dio.post('/conversations/$conversationId/messages', data: {
      'text': text,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    });
    return response.data as Map<String, dynamic>;
  }

  /// POST /conversations - Create a new conversation with a user
  /// Returns the conversation_id for the new or existing conversation
  Future<Map<String, dynamic>> getOrCreateConversation(String recipientId) async {
    final response = await _dio.post('/conversations', data: {
      'recipient_id': recipientId,
    });
    return response.data as Map<String, dynamic>;
  }
}
