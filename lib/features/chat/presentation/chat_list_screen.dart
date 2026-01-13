import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_repository.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: FutureBuilder<List<dynamic>>(
        future: ref.read(chatRepositoryProvider).listConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => (context as Element).markNeedsBuild(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final conversations = snapshot.data ?? [];
          
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No conversations yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final conversationId = conversation['id'] ?? '';
              final userName = conversation['user'] ?? 'Unknown';
              final lastMessage = conversation['last_message'] ?? '';
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/chat-room', extra: {
                  'conversation_id': conversationId,
                  'recipient_name': userName,
                }),
              );
            },
          );
        },
      ),
    );
  }
}
