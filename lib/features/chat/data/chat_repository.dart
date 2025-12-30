
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

  Future<List<dynamic>> listConversations() async {
    final response = await _dio.get('/conversations');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getHistory(String conversationId) async {
    final response = await _dio.get('/conversations/$conversationId/messages');
    return response.data as List<dynamic>;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _dio.post('/conversations/$conversationId/messages', data: {
      'content': content,
    });
  }
}
