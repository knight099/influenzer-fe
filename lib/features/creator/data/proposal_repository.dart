
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'proposal_repository.g.dart';

@riverpod
ProposalRepository proposalRepository(Ref ref) {
  return ProposalRepository(ref.watch(dioProvider));
}

class ProposalRepository {
  final Dio _dio;

  ProposalRepository(this._dio);

  /// POST /proposals - Create a new proposal
  Future<Map<String, dynamic>> createProposal(Map<String, dynamic> proposalData) async {
    final response = await _dio.post('/proposals', data: proposalData);
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /proposals/:id/status - Update proposal status
  Future<void> updateStatus(String id, String status) async {
    await _dio.patch('/proposals/$id/status', data: {
      'status': status,
    });
  }

  /// GET /proposals - List all proposals (for creators to view their proposals)
  Future<List<dynamic>> listProposals() async {
    final response = await _dio.get('/proposals');
    return response.data as List<dynamic>;
  }

  /// GET /proposals/:id - Get a specific proposal by ID
  Future<Map<String, dynamic>> getProposal(String id) async {
    final response = await _dio.get('/proposals/$id');
    return response.data as Map<String, dynamic>;
  }

  /// GET /proposals/campaign/:campaignId - Get proposals for a specific campaign
  Future<List<dynamic>> getProposalsByCampaign(String campaignId) async {
    final response = await _dio.get('/proposals/campaign/$campaignId');
    return response.data as List<dynamic>;
  }

  /// POST /proposals/:id/submit-proof - Submit proof for a proposal
  Future<void> submitProof(String id, String proofUrl) async {
    await _dio.post('/proposals/$id/submit-proof', data: {
      'proofUrl': proofUrl,
    });
  }
}
