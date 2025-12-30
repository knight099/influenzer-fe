
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

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final response = await _dio.post('/payments/create-order', data: orderData);
    return response.data as Map<String, dynamic>;
  }

  Future<void> verifyPayment(Map<String, dynamic> paymentData) async {
    await _dio.post('/payments/verify', data: paymentData);
  }
  
  Future<List<dynamic>> getTransactions() async {
    final response = await _dio.get('/wallet/transactions');
    return response.data as List<dynamic>;
  }

  Future<void> releaseFunds(Map<String, dynamic> releaseData) async {
    await _dio.post('/payments/release', data: releaseData);
  }
}
