import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'brand_profile_repository.g.dart';

class BrandProfile {
  final String? companyName;
  final String? contactName;
  final String? phone;
  final String? roleInCompany;
  final String? website;
  final String? logoUrl;
  final double walletBalance;
  final String subscriptionStatus;
  // Extended profile
  final String? industry;
  final String? description;
  final int? foundedYear;
  final String? companySize;
  final String? headquarters;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? linkedinUrl;
  final String? productCategories;
  final String? targetAudience;
  final String? campaignTypes;

  BrandProfile({
    this.companyName,
    this.contactName,
    this.phone,
    this.roleInCompany,
    this.website,
    this.logoUrl,
    this.walletBalance = 0.0,
    this.subscriptionStatus = 'INACTIVE',
    this.industry,
    this.description,
    this.foundedYear,
    this.companySize,
    this.headquarters,
    this.instagramUrl,
    this.twitterUrl,
    this.linkedinUrl,
    this.productCategories,
    this.targetAudience,
    this.campaignTypes,
  });

  factory BrandProfile.fromJson(Map<String, dynamic> json) {
    return BrandProfile(
      companyName: json['company_name'],
      contactName: json['contact_name'],
      phone: json['phone'],
      roleInCompany: json['role_in_company'],
      website: json['website'],
      logoUrl: json['logo_url']?.toString(),
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      subscriptionStatus: (json['is_subscribed'] == true) ? 'ACTIVE' : 'INACTIVE',
      industry: json['industry'],
      description: json['description'],
      foundedYear: json['founded_year'] as int?,
      companySize: json['company_size'],
      headquarters: json['headquarters'],
      instagramUrl: json['instagram_url'],
      twitterUrl: json['twitter_url'],
      linkedinUrl: json['linkedin_url'],
      productCategories: json['product_categories'],
      targetAudience: json['target_audience'],
      campaignTypes: json['campaign_types'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand_name': companyName,
      'contact_name': contactName,
      'phone': phone,
      'role_in_company': roleInCompany,
      'website': website,
      'industry': industry,
      'description': description,
      'founded_year': foundedYear,
      'company_size': companySize,
      'headquarters': headquarters,
      'instagram_url': instagramUrl,
      'twitter_url': twitterUrl,
      'linkedin_url': linkedinUrl,
      'product_categories': productCategories,
      'target_audience': targetAudience,
      'campaign_types': campaignTypes,
    };
  }
}

@riverpod
BrandProfileRepository brandProfileRepository(Ref ref) {
  return BrandProfileRepository(ref.watch(dioProvider));
}

@riverpod
Future<BrandProfile> brandProfile(Ref ref) async {
  return ref.watch(brandProfileRepositoryProvider).getProfile();
}

class BrandProfileRepository {
  final Dio _dio;

  BrandProfileRepository(this._dio);

  Future<BrandProfile> getProfile() async {
    final response = await _dio.get('/api/brands/profile');
    // Backend returns data directly, not wrapped in "profile"
    return BrandProfile.fromJson(response.data);
  }

  Future<void> updateProfile(BrandProfile profile) async {
    await _dio.put('/api/brands/profile', data: profile.toJson());
  }

  Future<Map<String, dynamic>> getBrandProfile(String brandId) async {
    final response = await _dio.get('/api/brands/$brandId');
    return response.data as Map<String, dynamic>;
  }
}
