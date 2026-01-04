
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

  /// POST /campaigns - Create a new campaign
  Future<Map<String, dynamic>> createCampaign(Map<String, dynamic> campaignData) async {
    final response = await _dio.post('/campaigns', data: campaignData);
    return response.data as Map<String, dynamic>;
  }

  /// GET /campaigns - List all campaigns for the brand
  Future<List<dynamic>> listCampaigns() async {
    final response = await _dio.get('/campaigns');
    return response.data as List<dynamic>;
  }

  /// GET /campaigns/:id - Get a specific campaign by ID
  Future<Map<String, dynamic>> getCampaign(String id) async {
    final response = await _dio.get('/campaigns/$id');
    return response.data as Map<String, dynamic>;
  }
}

