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

class InstagramStats {
  final String? username;
  final String? profilePictureUrl;
  final String? followersCount;
  final String? followingCount;
  final String? mediaCount;
  final String? biography;

  InstagramStats({
    this.username,
    this.profilePictureUrl,
    this.followersCount,
    this.followingCount,
    this.mediaCount,
    this.biography,
  });

  factory InstagramStats.fromJson(Map<String, dynamic> json) {
    return InstagramStats(
      username: json['username'],
      profilePictureUrl: json['profile_picture'], // Backend sends profile_picture
      followersCount: json['followers_count']?.toString(),
      followingCount: json['follows_count']?.toString(), // Backend sends follows_count
      mediaCount: json['media_count']?.toString(),
      biography: json['biography'],
    );
  }
}

class SubscriptionInfo {
  final String? planName;
  final String? planId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  SubscriptionInfo({
    this.planName,
    this.planId,
    this.startDate,
    this.endDate,
    this.status = 'inactive',
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      planName: json['plan_name'],
      planId: json['plan_id'],
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
      status: json['status'] ?? 'inactive',
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
  final InstagramStats? instagramStats;
  final String? instagramError;
  final String subscriptionStatus;
  final bool isSubscribed;
  final SubscriptionInfo? subscription;
  final double walletBalance;

  // Extended creator profile fields
  final String? bio;
  final String? languages;
  final int yearsExperience;
  final String? contentCategories;
  final String? pastBrands;
  final Map<String, dynamic>? rateCard;
  final Map<String, dynamic>? socialLinks;
  final String? city;
  final String? phone;
  final double minBudget;

  // Professional identity
  final String? headline;
  final String? gender;
  final DateTime? dateOfBirth;
  final int profileComplete;

  // Availability & logistics
  final String availabilityStatus;
  final int turnaroundDays;
  final String? location;
  final String? pinCode;
  final bool willingToTravel;

  // Audience demographics
  final Map<String, dynamic>? audienceDemographics;

  // Collaboration preferences
  final Map<String, dynamic>? collaborationPrefs;

  // Structured past work
  final List<Map<String, dynamic>> pastWork;

  // Portfolio items
  final List<Map<String, dynamic>> portfolio;

  // Performance metrics
  final int totalCampaigns;
  final int completedCampaigns;
  final double avgRating;
  final String? responseTime;

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
    this.instagramStats,
    this.instagramError,
    this.subscriptionStatus = 'INACTIVE',
    this.isSubscribed = false,
    this.subscription,
    this.walletBalance = 0.0,
    this.bio,
    this.languages,
    this.yearsExperience = 0,
    this.contentCategories,
    this.pastBrands,
    this.rateCard,
    this.socialLinks,
    this.city,
    this.phone,
    this.minBudget = 0.0,
    // New fields
    this.headline,
    this.gender,
    this.dateOfBirth,
    this.profileComplete = 0,
    this.availabilityStatus = 'available',
    this.turnaroundDays = 0,
    this.location,
    this.pinCode,
    this.willingToTravel = false,
    this.audienceDemographics,
    this.collaborationPrefs,
    this.pastWork = const [],
    this.portfolio = const [],
    this.totalCampaigns = 0,
    this.completedCampaigns = 0,
    this.avgRating = 0.0,
    this.responseTime,
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
    YouTubeStats? ytStats;
    String? ytError;
    InstagramStats? igStats;
    String? igError;
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
      
      if (cachedStats['instagram'] != null) {
        igStats = InstagramStats.fromJson(cachedStats['instagram'] as Map<String, dynamic>);
        // Use Instagram username as username if not already set
        igUsername ??= igStats.username;
      }
      if (cachedStats['instagram_error'] != null) {
        igError = cachedStats['instagram_error'].toString();
      }
    }

    // Parse subscription info from new API format
    final isSubscribed = json['is_subscribed'] == true;
    SubscriptionInfo? subscriptionInfo;
    if (json['subscription'] != null && json['subscription'] is Map<String, dynamic>) {
      subscriptionInfo = SubscriptionInfo.fromJson(json['subscription']);
    }
    
    // Derive subscriptionStatus from is_subscribed for backward compatibility
    final subscriptionStatus = isSubscribed ? 'ACTIVE' : 'INACTIVE';

    // Parse extended creator profile fields from nested creator_profile object
    final cp = json['creator_profile'] as Map<String, dynamic>?;

    // Parse past_work as List<Map>
    final rawPastWork = cp?['past_work'] as List<dynamic>? ?? [];
    final pastWork = rawPastWork.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Parse portfolio as List<Map>
    final rawPortfolio = cp?['portfolio'] as List<dynamic>? ?? [];
    final portfolio = rawPortfolio.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Parse date_of_birth
    DateTime? dateOfBirth;
    if (cp?['date_of_birth'] != null) {
      dateOfBirth = DateTime.tryParse(cp!['date_of_birth'].toString());
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
      instagramStats: igStats,
      instagramError: igError,
      subscriptionStatus: subscriptionStatus,
      isSubscribed: isSubscribed,
      subscription: subscriptionInfo,
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      bio: cp?['bio'] as String?,
      languages: cp?['languages'] as String?,
      yearsExperience: (cp?['years_experience'] as int?) ?? 0,
      contentCategories: cp?['content_categories'] as String?,
      pastBrands: cp?['past_brands'] as String?,
      rateCard: cp?['rate_card'] as Map<String, dynamic>?,
      socialLinks: cp?['social_links'] as Map<String, dynamic>?,
      city: cp?['city'] as String?,
      phone: cp?['phone'] as String?,
      minBudget: ((cp?['min_budget']) ?? 0).toDouble(),
      // New fields
      headline: cp?['headline'] as String?,
      gender: cp?['gender'] as String?,
      dateOfBirth: dateOfBirth,
      profileComplete: (json['profile_complete'] as int?) ?? 0,
      availabilityStatus: (cp?['availability_status'] as String?) ?? 'available',
      turnaroundDays: (cp?['turnaround_days'] as int?) ?? 0,
      location: cp?['location'] as String?,
      pinCode: cp?['pin_code'] as String?,
      willingToTravel: (cp?['willing_to_travel'] as bool?) ?? false,
      audienceDemographics: cp?['audience_demographics'] as Map<String, dynamic>?,
      collaborationPrefs: cp?['collaboration_prefs'] as Map<String, dynamic>?,
      pastWork: pastWork,
      portfolio: portfolio,
      totalCampaigns: (json['total_campaigns'] as int?) ?? 0,
      completedCampaigns: (json['completed_campaigns'] as int?) ?? 0,
      avgRating: ((json['avg_rating']) ?? 0).toDouble(),
      responseTime: json['response_time'] as String?,
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

