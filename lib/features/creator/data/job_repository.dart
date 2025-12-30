
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

  Future<List<dynamic>> getFeed() async {
    final response = await _dio.get('/jobs/feed');
    return response.data as List<dynamic>;
  }

  Future<void> apply(String jobId, Map<String, dynamic> applicationData) async {
    await _dio.post('/jobs/$jobId/apply', data: applicationData);
  }

  Future<List<dynamic>> myApplications() async {
    final response = await _dio.get('/jobs/my-applications');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPresignedUrl(String fileName, String fileType) async {
    final response = await _dio.post('/upload/presigned', data: {
      'fileName': fileName,
      'fileType': fileType,
    });
    return response.data as Map<String, dynamic>;
  }
}
