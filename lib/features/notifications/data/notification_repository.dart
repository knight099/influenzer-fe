import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String resourceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.resourceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      resourceId: json['resource_id'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        resourceId: resourceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotification>> list() async {
    final resp = await _dio.get('/notifications');
    final data = resp.data as List<dynamic>;
    return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> unreadCount() async {
    final resp = await _dio.get('/notifications/unread-count');
    return resp.data['count'] as int? ?? 0;
  }

  Future<void> markRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> registerDeviceToken(String token, String platform) async {
    await _dio.post('/notifications/device-token', data: {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _dio.delete('/notifications/device-token', data: {'token': token});
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationRepositoryProvider).list();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).unreadCount();
});
