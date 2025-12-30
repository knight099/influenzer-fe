
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'creator_repository.g.dart';

@riverpod
CreatorRepository creatorRepository(Ref ref) {
  return CreatorRepository(ref.watch(dioProvider));
}

class CreatorRepository {
  final Dio _dio;

  CreatorRepository(this._dio);

  Future<List<dynamic>> searchCreators() async {
    final response = await _dio.get('/creators/search');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProfile(String id) async {
    final response = await _dio.get('/creators/$id');
    return response.data as Map<String, dynamic>;
  }
}
