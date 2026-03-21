
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

/// Spotlight creators — early adopters with connected platforms
@Riverpod(keepAlive: true)
Future<List<dynamic>> spotlightCreators(Ref ref) async {
  final repo = ref.watch(creatorRepositoryProvider);
  return repo.getSpotlight();
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

  /// GET /creators/spotlight - Early adopters with connected platforms
  Future<List<dynamic>> getSpotlight() async {
    final response = await _dio.get('/creators/spotlight');
    return response.data as List<dynamic>;
  }

  /// GET /creators/:id/media?platform=instagram|youtube&limit=N
  /// Returns { "instagram": [...], "youtube": [...] }
  Future<Map<String, dynamic>> getCreatorMedia(
    String id, {
    String? platform,
    int limit = 12,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (platform != null) queryParams['platform'] = platform;
    final response = await _dio.get(
      '/creators/$id/media',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /creators/:id/analytics
  Future<Map<String, dynamic>> getCreatorAnalytics(String id) async {
    final response = await _dio.get('/creators/$id/analytics');
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/creators/profile — update extended profile fields
  Future<void> updateCreatorProfile(Map<String, dynamic> data) async {
    await _dio.put('/api/creators/profile', data: data);
  }
}
