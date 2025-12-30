
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'campaign_repository.g.dart';

@riverpod
CampaignRepository campaignRepository(Ref ref) {
  return CampaignRepository(ref.watch(dioProvider));
}

class CampaignRepository {
  final Dio _dio;

  CampaignRepository(this._dio);

  Future<void> createCampaign(Map<String, dynamic> campaignData) async {
    await _dio.post('/campaigns', data: campaignData);
  }

  Future<List<dynamic>> listCampaigns() async {
    final response = await _dio.get('/campaigns');
    return response.data as List<dynamic>;
  }
}
