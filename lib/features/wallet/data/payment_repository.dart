
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'payment_repository.g.dart';

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepository(ref.watch(dioProvider));
}

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<Map<String, dynamic>> createOrder(String proposalId, int amount, String currency) async {
    final response = await _dio.post('/payments/create-order', data: {
      'proposal_id': proposalId,
      'amount': amount,
      'currency': currency,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> verifyPayment(String orderId, String paymentId, String signature) async {
    await _dio.post('/payments/verify', data: {
      'order_id': orderId,
      'payment_id': paymentId,
      'signature': signature,
    });
  }
  
  Future<List<dynamic>> getTransactions() async {
    final response = await _dio.get('/wallet/transactions');
    return response.data as List<dynamic>;
  }

  Future<void> releaseFunds(String proposalId) async {
    await _dio.post('/payments/release', data: {
      'proposal_id': proposalId,
    });
  }

  Future<List<dynamic>> getSubscriptionPlans() async {
    final response = await _dio.get('/payments/plans');
    return response.data as List<dynamic>;
  }

  /// Creates a subscription and returns subscription_id and short_url for payment
  Future<Map<String, dynamic>> subscribe(String planId) async {
    final response = await _dio.post('/payments/subscribe', data: {
      'plan_id': planId,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Checks the current user's subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final response = await _dio.get('/payments/subscription/status');
    return response.data as Map<String, dynamic>;
  }
}
