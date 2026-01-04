
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'creator_repository.g.dart';

@riverpod
CreatorRepository creatorRepository(Ref ref) {
  return CreatorRepository(ref.watch(dioProvider));
}

/// Cached creator search results - persists during app session
/// Automatically refetches when app restarts
@Riverpod(keepAlive: true)
Future<List<dynamic>> cachedCreatorSearch(Ref ref) async {
  final repo = ref.watch(creatorRepositoryProvider);
  return repo.searchCreators();
}

class CreatorRepository {
  final Dio _dio;

  CreatorRepository(this._dio);

  /// GET /creators/search - Search creators with filters (platform, niche, etc.)
  Future<List<dynamic>> searchCreators() async {
    final response = await _dio.get('/creators/search');
    return response.data as List<dynamic>;
  }

  /// GET /creators/:id - Get a specific creator by ID
  Future<Map<String, dynamic>> getProfile(String id) async {
    final response = await _dio.get('/creators/$id');
    return response.data as Map<String, dynamic>;
  }
}
