
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

  /// GET /campaigns/my - List campaigns owned by the authenticated brand
  Future<List<dynamic>> listMyCampaigns() async {
    final response = await _dio.get('/campaigns/my');
    return (response.data as List<dynamic>?) ?? [];
  }

  /// GET /campaigns/invitations - List campaigns the creator was invited to
  Future<List<dynamic>> getInvitations() async {
    final response = await _dio.get('/campaigns/invitations');
    return (response.data as List<dynamic>?) ?? [];
  }

  /// GET /campaigns/my/invitable/:creatorId - Open campaigns the creator hasn't applied to or been invited to
  Future<List<dynamic>> listInvitableCampaigns(String creatorId) async {
    final response = await _dio.get('/campaigns/my/invitable/$creatorId');
    return (response.data as List<dynamic>?) ?? [];
  }

  /// POST /campaigns/:id/invite - Invite a creator to a campaign
  Future<void> inviteCreator(String campaignId, String creatorId) async {
    await _dio.post('/campaigns/$campaignId/invite', data: {
      'creator_id': creatorId,
    });
  }

  /// PATCH /campaigns/:id/close - End (close) a campaign
  Future<void> closeCampaign(String campaignId) async {
    await _dio.patch('/campaigns/$campaignId/close');
  }

  /// DELETE /campaigns/:id - Delete a closed campaign
  Future<void> deleteCampaign(String campaignId) async {
    await _dio.delete('/campaigns/$campaignId');
  }
}

