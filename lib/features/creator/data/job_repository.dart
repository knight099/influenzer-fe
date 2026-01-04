
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'job_repository.g.dart';

@riverpod
JobRepository jobRepository(Ref ref) {
  return JobRepository(ref.watch(dioProvider));
}

class JobRepository {
  final Dio _dio;

  JobRepository(this._dio);

  /// GET /jobs/feed - Get the job feed for creators
  Future<List<dynamic>> getFeed() async {
    final response = await _dio.get('/jobs/feed');
    return response.data as List<dynamic>;
  }

  /// POST /jobs/:jobId/apply - Apply to a specific job
  Future<void> apply(String jobId, Map<String, dynamic> applicationData) async {
    await _dio.post('/jobs/$jobId/apply', data: applicationData);
  }

  /// GET /jobs/my-applications - Get all applications submitted by the creator
  Future<List<dynamic>> myApplications() async {
    final response = await _dio.get('/jobs/my-applications');
    return response.data as List<dynamic>;
  }

  /// POST /upload/presigned - Get presigned URL for video upload
  Future<Map<String, dynamic>> getPresignedUrl(String fileName, String fileType) async {
    final response = await _dio.post('/upload/presigned', data: {
      'fileName': fileName,
      'fileType': fileType,
    });
    return response.data as Map<String, dynamic>;
  }
}
