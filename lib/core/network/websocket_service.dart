import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';

part 'websocket_service.g.dart';

/// Message types for WebSocket communication
class ChatMessage {
  final String type;
  final String? messageId;
  final String? text;
  final String? senderId;
  final String? senderName;
  final String? timestamp;
  final String? attachmentUrl;

  ChatMessage({
    required this.type,
    this.messageId,
    this.text,
    this.senderId,
    this.senderName,
    this.timestamp,
    this.attachmentUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      type: json['type'] ?? 'message',
      messageId: json['message_id']?.toString(),
      text: json['text']?.toString(),
      senderId: json['sender_id']?.toString(),
      senderName: json['sender_name']?.toString(),
      timestamp: json['timestamp']?.toString(),
      attachmentUrl: json['attachment_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (text != null) 'text': text,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
  };
}

/// WebSocket service for real-time chat
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<String> _typingController = StreamController<String>.broadcast();
  
  String? _currentRoomId;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  /// Stream of incoming messages
  Stream<ChatMessage> get messageStream => _messageController.stream;
  
  /// Stream of connection status
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Stream of typing indicators (emits sender_id when someone is typing)
  Stream<String> get typingStream => _typingController.stream;
  
  /// Current connection state
  bool get isConnected => _isConnected;

  /// Connect to a chat room via WebSocket
  Future<void> connect(String roomId) async {
    // Don't reconnect if already connected to same room
    if (_isConnected && _currentRoomId == roomId) return;
    
    // Disconnect from any existing connection
    await disconnect();
    
    _currentRoomId = roomId;
    final token = AuthTokenHolder.token;
    
    if (token == null || token.isEmpty) {
      print('[WebSocket] No auth token available');
      return;
    }

    try {
      final wsUrl = Uri.parse(
        'wss://influenzer.onrender.com/ws/chat?room_id=$roomId&token=$token'
      );
      
      print('[WebSocket] Connecting to: $wsUrl');
      
      _channel = WebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      
      print('[WebSocket] Connected to room: $roomId');
    } catch (e) {
      print('[WebSocket] Connection error: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = json['type'] ?? 'message';
      
      if (type == 'typing') {
        // Typing indicator
        final senderId = json['sender_id']?.toString() ?? '';
        _typingController.add(senderId);
      } else {
        // Regular message
        final message = ChatMessage.fromJson(json);
        _messageController.add(message);
      }
    } catch (e) {
      print('[WebSocket] Error parsing message: $e');
    }
  }

  void _handleError(dynamic error) {
    print('[WebSocket] Error: $error');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    print('[WebSocket] Disconnected');
    _isConnected = false;
    _connectionController.add(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[WebSocket] Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: 2 * (_reconnectAttempts + 1)), // Exponential backoff
      () {
        if (_currentRoomId != null && !_isConnected) {
          _reconnectAttempts++;
          print('[WebSocket] Reconnect attempt $_reconnectAttempts');
          connect(_currentRoomId!);
        }
      },
    );
  }

  /// Send a message via WebSocket
  void sendMessage(String text, {String? attachmentUrl}) {
    if (!_isConnected || _channel == null) {
      print('[WebSocket] Cannot send - not connected');
      return;
    }

    final message = ChatMessage(
      type: 'message',
      text: text,
      attachmentUrl: attachmentUrl,
    );
    
    _channel!.sink.add(jsonEncode(message.toJson()));
  }

  /// Send typing indicator
  void sendTyping() {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({'type': 'typing'}));
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
    
    _isConnected = false;
    _currentRoomId = null;
    _connectionController.add(false);
    
    print('[WebSocket] Disconnected');
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _typingController.close();
  }
}

/// Global WebSocket service provider
@Riverpod(keepAlive: true)
WebSocketService webSocketService(Ref ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
}
