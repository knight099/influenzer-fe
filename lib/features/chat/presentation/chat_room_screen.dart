import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_repository.dart';

import 'dart:async';
import 'package:influenzer_app/features/auth/application/auth_controller.dart';
import 'package:influenzer_app/core/network/websocket_service.dart';
import 'dart:convert';
import 'package:influenzer_app/features/creator/data/user_profile_repository.dart';
import 'package:influenzer_app/core/network/api_client.dart';

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
  Set<String> _typingUsers = {};
  Timer? _typingTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;
  String? _conversationId;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _initializeChat();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }





  Future<void> _initializeChat() async {
    // 1. Get current user ID from token (Most reliable source for ID)
    _currentUserId = _getUserIdFromToken();
    print('[ChatDebug] Resolved currentUserId from token: $_currentUserId');

    // 2. Load message history if conversation exists
    if (_conversationId != null) {
      await _loadMessages();
      _connectWebSocket();
    } else {
      setState(() => _isLoading = false);
    }
  }

  String? _getUserIdFromToken() {
    final token = AuthTokenHolder.token;
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      if (payloadMap is Map<String, dynamic>) {
        return payloadMap['sub'] ?? payloadMap['id'] ?? payloadMap['user_id'];
      }
      return null;
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ref.read(chatRepositoryProvider).getMessages(_conversationId!);
      if (mounted) {
        setState(() {
          _messages = messages.map((m) => m as Map<String, dynamic>).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Don't show error snackbar on load, just log it
        print('Error loading messages: $e');
      }
    }
  }

  void _connectWebSocket() {
    if (_conversationId == null) return;
    
    final wsService = ref.read(webSocketServiceProvider);
    wsService.connect(_conversationId!);

    // Listen for new messages
    _messageSubscription?.cancel();
    _messageSubscription = wsService.messageStream.listen((message) {
      if (mounted) {
        setState(() {

          // Check if message already exists (optimistic update)
          final exists = _messages.any((m) => 
            m['id'] == message.messageId || 
            (m['local_id'] != null && m['text'] == message.text && m['sender_id'] == message.senderId)
          );
          
          if (!exists) {
            final isMe = _currentUserId != null && message.senderId == _currentUserId;
            
            _messages.add({
              'id': message.messageId,
              'text': message.text,
              'sender_id': message.senderId,
              'timestamp': message.timestamp ?? DateTime.now().toIso8601String(),
              'is_me': isMe,
            });
            _scrollToBottom();
          }
          
          // Remove from typing users if they sent a message
          if (message.senderId != null) {
            _typingUsers.remove(message.senderId);
          }
        });
      }
    });

    // Listen for typing indicators
    _typingSubscription?.cancel();
    _typingSubscription = wsService.typingStream.listen((senderId) {
      if (senderId != _currentUserId && mounted) {
        setState(() {
          _typingUsers.add(senderId);
        });
        
        // Remove typing indicator after 3 seconds of inactivity
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _typingUsers.remove(senderId);
            });
          }
        });
      }
    });
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

  void _onTextChanged(String text) {
    if (_conversationId != null && text.isNotEmpty) {
      // Throttle typing events
      if (_typingTimer?.isActive ?? false) return;
      
      ref.read(webSocketServiceProvider).sendTyping();
      _typingTimer = Timer(const Duration(seconds: 2), () {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    _controller.clear();

    try {
      // Optimization: Show message immediately
      setState(() {
        _messages.add({
          'local_id': localId,
          'text': text,
          'sender_id': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'is_me': true,
          'status': 'sending',
        });
      });
      _scrollToBottom();

      // If no conversation exists, create one first
      if (_conversationId == null) {
        if (widget.recipientId == null) {
          throw Exception('No recipient specified');
        }
        
        setState(() => _isSending = true);
        final convResponse = await ref.read(chatRepositoryProvider)
            .getOrCreateConversation(widget.recipientId!);
        
        _conversationId = convResponse['id']?.toString() ?? convResponse['conversation_id']?.toString();
        
        if (_conversationId == null) {
          throw Exception('Failed to create conversation');
        }
        
        // Connect WebSocket now that we have a room
        _connectWebSocket();
        setState(() => _isSending = false);
      }

      // Send via WebSocket if connected, otherwise fallback to REST
      final wsService = ref.read(webSocketServiceProvider);
      if (wsService.isConnected) {
        wsService.sendMessage(text);
        // WebSocket stream will confirm the message, but we already showed it optimistically
        // Update status to sent
        setState(() {
           final index = _messages.indexWhere((m) => m['local_id'] == localId);
           if (index != -1) {
             _messages[index]['status'] = 'sent';
           }
        });
      } else {
        // Fallback to REST
        final response = await ref.read(chatRepositoryProvider).sendMessage(
          _conversationId!,
          text,
        );
        
        // Update the optimistic message with real ID
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m['local_id'] == localId);
            if (index != -1) {
              _messages[index] = {
                ..._messages[index],
                'id': response['id'],
                'status': 'sent',
              };
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Mark message as failed
          final index = _messages.indexWhere((m) => m['local_id'] == localId);
          if (index != -1) {
            _messages[index]['status'] = 'failed';
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipientName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_typingUsers.isNotEmpty)
                    const Text(
                      'Typing...',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontStyle: FontStyle.italic),
                    ),
                ],
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
                          // Determine if message is from current user
                          final isMe = message['is_me'] == true || 
                                       (message['sender_id'] != null && message['sender_id'] == _currentUserId);
                          
                          return _MessageBubble(
                            message: text,
                            isMe: isMe,
                            timestamp: message['timestamp'],
                            status: message['status'],
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
                      onChanged: _onTextChanged,
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
  final String? status;

  const _MessageBubble({
    required this.message, 
    required this.isMe,
    this.timestamp,
    this.status,
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
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp!),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  if (isMe && status != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      status == 'sending' ? Icons.access_time : 
                      status == 'failed' ? Icons.error_outline : Icons.done,
                      size: 12,
                      color: status == 'failed' ? Colors.red : Colors.white70,
                    ),
                  ],
                ],
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
