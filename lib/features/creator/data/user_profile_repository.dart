import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'user_profile_repository.g.dart';

class YouTubeStats {
  final String? channelTitle;
  final String? channelUrl;
  final String? subscriberCount;
  final String? viewCount;
  final String? videoCount;
  final String? thumbnail;

  YouTubeStats({
    this.channelTitle,
    this.channelUrl,
    this.subscriberCount,
    this.viewCount,
    this.videoCount,
    this.thumbnail,
  });

  factory YouTubeStats.fromJson(Map<String, dynamic> json) {
    return YouTubeStats(
      channelTitle: json['channel_title'],
      channelUrl: json['channel_url'],
      subscriberCount: json['subscriber_count'],
      viewCount: json['view_count'],
      videoCount: json['video_count'],
      thumbnail: json['thumbnail'],
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String role;
  final String? name;
  final String? avatarUrl;
  final bool youtubeConnected;
  final bool instagramConnected;
  final String? youtubeChannelName;
  final String? instagramUsername;
  final YouTubeStats? youtubeStats;
  final String? youtubeError;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.avatarUrl,
    this.youtubeConnected = false,
    this.instagramConnected = false,
    this.youtubeChannelName,
    this.instagramUsername,
    this.youtubeStats,
    this.youtubeError,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle connected_platforms from the response
    final connectedPlatforms = json['connected_platforms'] as List<dynamic>? ?? [];
    
    bool ytConnected = false;
    bool igConnected = false;
    String? ytChannel;
    String? igUsername;
    
    for (final platform in connectedPlatforms) {
      if (platform is Map<String, dynamic>) {
        final platformName = platform['platform']?.toString().toLowerCase();
        final isConnected = platform['connected'] == true;
        
        if (platformName == 'youtube' && isConnected) {
          ytConnected = true;
          ytChannel = platform['channel_name'] ?? platform['username'];
        } else if (platformName == 'instagram' && isConnected) {
          igConnected = true;
          igUsername = platform['username'];
        }
      }
    }

    // Parse cached_stats
    // Parse cached_stats
    YouTubeStats? ytStats;
    String? ytError;
    final cachedStats = json['cached_stats'] as Map<String, dynamic>?;
    print('[Profile] raw cached_stats: $cachedStats');

    if (cachedStats != null) {
      if (cachedStats['youtube'] != null) {
        ytStats = YouTubeStats.fromJson(cachedStats['youtube'] as Map<String, dynamic>);
        // Use channel title as channel name if not already set
        ytChannel ??= ytStats.channelTitle;
      }
      if (cachedStats['youtube_error'] != null) {
        ytError = cachedStats['youtube_error'].toString();
      }
    }

    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CREATOR',
      name: json['name'],
      avatarUrl: json['avatar_url'],
      youtubeConnected: ytConnected,
      instagramConnected: igConnected,
      youtubeChannelName: ytChannel,
      instagramUsername: igUsername,
      youtubeStats: ytStats,
      youtubeError: ytError,
    );
  }
}

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  return UserProfileRepository(ref.watch(dioProvider));
}

@riverpod
Future<UserProfile> userProfile(Ref ref) async {
  return ref.watch(userProfileRepositoryProvider).getProfile();
}

class UserProfileRepository {
  final Dio _dio;

  UserProfileRepository(this._dio);

  Future<UserProfile> getProfile() async {
    final response = await _dio.get('/api/creators/profile');
    return UserProfile.fromJson(response.data);
  }

  Future<void> refreshStats() async {
    await _dio.post('/api/creators/refresh-stats');
  }
}

