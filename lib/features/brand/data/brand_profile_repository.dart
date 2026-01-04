import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:influenzer_app/core/network/api_client.dart';

part 'brand_profile_repository.g.dart';

class BrandProfile {
  final String? companyName;
  final String? contactName;
  final String? phone;
  final String? roleInCompany;
  final double walletBalance;
  final String subscriptionStatus;

  BrandProfile({
    this.companyName,
    this.contactName,
    this.phone,
    this.roleInCompany,
    this.walletBalance = 0.0,
    this.subscriptionStatus = 'INACTIVE',
  });

  factory BrandProfile.fromJson(Map<String, dynamic> json) {
    return BrandProfile(
      companyName: json['company_name'],
      contactName: json['contact_name'],
      phone: json['phone'],
      roleInCompany: json['role_in_company'],
      walletBalance: (json['wallet_balance'] ?? 0).toDouble(),
      subscriptionStatus: json['subscription_status'] ?? 'INACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand_name': companyName,
      'contact_name': contactName,
      'phone': phone,
      'role_in_company': roleInCompany,
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
}
