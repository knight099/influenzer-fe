import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:influenzer_app/core/network/mock_config.dart';
import 'package:influenzer_app/core/network/mock_data.dart';

class MockInterceptor extends Interceptor {
  final Ref ref;

  MockInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final useMockData = ref.read(useMockDataProvider);

    if (!useMockData) {
      // Proceed with real API call
      return handler.next(options);
    }

    // Add artificial delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    final path = options.path;
    final method = options.method.toUpperCase();

    dynamic mockResponseData;
    int statusCode = 200;

    try {
      // Auth
      if (path.contains('/auth/mock-login')) {
        final role = options.data['role'] ?? 'CREATOR';
        mockResponseData = MockData.generateAuthResponse(role);
      }
      else if (path.contains('/auth/login/social') || path.contains('/auth/google')) {
        mockResponseData = {'user': MockData.mockCreatorProfile, 'token': 'mock_token'};
      }
      // Creator Profile
      else if (path.contains('/api/creators/profile')) {
        mockResponseData = MockData.mockCreatorProfile;
      }
      // Creator Analytics
      else if (path.contains('/api/creators/') && path.endsWith('/analytics')) {
        mockResponseData = MockData.mockCreatorAnalytics;
      }
      // Creator Media (Instagram / YouTube posts)
      else if (path.contains('/creators/') && path.contains('/media')) {
        final platform = options.queryParameters['platform']?.toString();
        mockResponseData = MockData.mockCreatorMedia(platform);
      }
      // Creator Search / Spotlight
      else if (path.contains('/creators/search') || path.contains('/creators/spotlight')) {
        mockResponseData = MockData.mockCreatorsList;
      }
      // Brand Profile
      else if (path.contains('/api/brands/profile')) {
        mockResponseData = MockData.mockBrandProfile;
      }
      // Jobs Feed (Creator)
      else if (path.contains('/jobs/feed')) {
        mockResponseData = MockData.mockJobFeed;
      }
      // My Applications (Creator)
      else if (path.contains('/jobs/my-applications')) {
        mockResponseData = MockData.mockApplications;
      }
      // Apply to Job
      else if (path.contains('/jobs/') && path.endsWith('/apply') && method == 'POST') {
        mockResponseData = {'success': true, 'message': 'Applied successfully (Mock)'};
      }
      // Brand Campaigns (Brand)
      else if (path.contains('/campaigns/my')) {
        mockResponseData = MockData.mockBrandCampaigns;
      }
      // All Campaigns (Brand)
      else if (path.contains('/campaigns') && method == 'GET') {
        mockResponseData = MockData.mockBrandCampaigns;
      }
      // Create Campaign
      else if (path.contains('/campaigns') && method == 'POST') {
        mockResponseData = {'success': true, 'id': 'camp_new', ...options.data};
      }
      // Conversations
      else if (path.contains('/conversations') && !path.contains('/messages') && method == 'GET') {
        mockResponseData = MockData.mockConversations;
      }
      // Messages in a conversation
      else if (path.contains('/messages') && method == 'GET') {
        mockResponseData = MockData.mockMessages;
      }
      // Send a message
      else if (path.contains('/messages') && method == 'POST') {
        final newMsg = {
          'id': 'msg_new_${DateTime.now().millisecondsSinceEpoch}',
          'sender_id': 'me',
          'text': options.data['text'],
          'created_at': DateTime.now().toIso8601String(),
        };
        mockResponseData = newMsg;
      }
      // Proposals
      else if (path.contains('/proposals')) {
        mockResponseData = [];
      }
      // Wallet
      else if (path.contains('/wallet/transactions')) {
        mockResponseData = [];
      }
      // Subscription
      else if (path.contains('/payments/subscription/status')) {
        mockResponseData = {'status': 'active', 'plan_name': 'Pro'};
      }
      // Notifications
      else if (path.contains('/notifications/unread-count')) {
        mockResponseData = {'count': 0};
      }
      else if (path.contains('/notifications')) {
        mockResponseData = [];
      }
      // Default / Not Found in Mock
      else {
        // Return empty map to prevent UI crashes for unhandled mock endpoints
        mockResponseData = {};
      }

      // Return successful mock response
      return handler.resolve(
        Response(
          requestOptions: options,
          data: mockResponseData,
          statusCode: statusCode,
        ),
      );
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}
