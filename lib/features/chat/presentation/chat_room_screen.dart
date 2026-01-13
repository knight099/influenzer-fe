import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_repository.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? recipientId;
  final String? recipientName;
  final String? recipientAvatar;

  const ChatRoomScreen({
    super.key,
    this.conversationId,
    this.recipientId,
    this.recipientName,
    this.recipientAvatar,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final messages = await ref.read(chatRepositoryProvider).getMessages(widget.conversationId!);
      setState(() {
        _messages = messages.map((m) => m as Map<String, dynamic>).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _conversationId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversationId = widget.conversationId;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() => _isSending = true);
    _controller.clear();

    try {
      // If no conversation exists, create one first
      if (_conversationId == null) {
        if (widget.recipientId == null) {
          throw Exception('No recipient specified');
        }
        
        final convResponse = await ref.read(chatRepositoryProvider)
            .getOrCreateConversation(widget.recipientId!);
        _conversationId = convResponse['id']?.toString() ?? convResponse['conversation_id']?.toString();
        
        if (_conversationId == null) {
          throw Exception('Failed to create conversation');
        }
      }

      final response = await ref.read(chatRepositoryProvider).sendMessage(
        _conversationId!,
        text,
      );
      
      // Add optimistic message
      setState(() {
        _messages.add({
          'id': response['id'],
          'text': text,
          'sender_id': _currentUserId ?? 'me',
          'timestamp': response['timestamp'] ?? DateTime.now().toIso8601String(),
          'is_me': true,
        });
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipientName = widget.recipientName ?? 'User';
    final recipientAvatar = widget.recipientAvatar;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              backgroundImage: recipientAvatar != null ? NetworkImage(recipientAvatar) : null,
              child: recipientAvatar == null 
                  ? Text(
                      recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recipientName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No messages yet', style: TextStyle(color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('Start the conversation!', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final text = message['text'] ?? message['content'] ?? '';
                          final senderId = message['sender_id']?.toString() ?? '';
                          // Determine if message is from current user
                          final isMe = message['is_me'] == true || 
                                       senderId == _currentUserId ||
                                       senderId == widget.recipientId; // fallback
                          
                          return _MessageBubble(
                            message: text,
                            isMe: !isMe, // Invert logic - if sender is recipient, it's not me
                            timestamp: message['timestamp'],
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // TODO: Implement attachment picker
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String? timestamp;

  const _MessageBubble({
    required this.message, 
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatTime(timestamp!),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }
}
