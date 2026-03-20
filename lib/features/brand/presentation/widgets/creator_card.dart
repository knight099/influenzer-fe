import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator['name'] ?? 'Unknown Creator';
    final niche = (creator['niche']?.toString().trim().isNotEmpty == true)
        ? creator['niche'].toString()
        : 'Creator';
    final city = creator['city']?.toString() ?? '';

    final instagramFollowers = creator['instagram_followers'] ?? 0;
    final youtubeSubscribers =
        int.tryParse(creator['youtube_subscribers']?.toString() ?? '0') ?? 0;

    int followers;
    String platform;
    bool isYouTube;

    if (youtubeSubscribers > instagramFollowers) {
      followers = youtubeSubscribers;
      platform = 'YouTube';
      isYouTube = true;
    } else {
      followers = instagramFollowers is int ? instagramFollowers : int.tryParse(instagramFollowers.toString()) ?? 0;
      platform = 'Instagram';
      isYouTube = false;
    }

    String? avatarUrl = creator['avatar_url'];
    if (creator['cached_stats'] != null) {
      final cs = creator['cached_stats'];
      avatarUrl = cs['instagram']?['profile_picture'] ?? cs['youtube']?['thumbnail'] ?? avatarUrl;
    }

    final startingPrice = creator['min_budget'] ?? 0;
    final isVerified = creator['verified'] == true;
    final hasBoth = creator['instagram_username'] != null && creator['youtube_channel_id'] != null;

    final platformColor = isYouTube ? AppColors.youtube : AppColors.instagram;
    final platformIcon = isYouTube ? Icons.play_circle_rounded : Icons.camera_alt_rounded;

    return GestureDetector(
      onTap: () => context.push('/creator-details', extra: creator),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with platform indicator
              Stack(
                children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarUrl == null ? AppColors.brandGradient : null,
                      color: avatarUrl != null ? AppColors.border : null,
                      border: Border.all(
                        color: platformColor.withOpacity(0.3), width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: avatarUrl != null
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Platform badge
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: platformColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Icon(platformIcon, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF1D9BF0)),
                        ],
                        if (hasBoth) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Multi',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      city.isNotEmpty ? '$niche • $city' : niche,
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        _StatPill(
                          icon: platformIcon,
                          iconColor: platformColor,
                          value: _formatNumber(followers),
                          label: platform,
                        ),
                        const SizedBox(width: 8),
                        if (startingPrice > 0)
                          _StatPill(
                            icon: Icons.currency_rupee_rounded,
                            iconColor: AppColors.success,
                            value: _formatBudget(startingPrice),
                            label: 'from',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right side action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  String _formatBudget(dynamic budget) {
    final amount = budget is int ? budget : int.tryParse(budget.toString()) ?? 0;
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
