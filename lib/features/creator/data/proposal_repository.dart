
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

  Future<void> createProposal(Map<String, dynamic> proposalData) async {
    await _dio.post('/proposals', data: proposalData);
  }

  Future<void> updateStatus(String id, String status) async {
    await _dio.patch('/proposals/$id/status', data: {
      'status': status,
    });
  }

  Future<void> submitProof(String id, String proofUrl) async {
    await _dio.post('/proposals/$id/submit-proof', data: {
      'proofUrl': proofUrl,
    });
  }
}
