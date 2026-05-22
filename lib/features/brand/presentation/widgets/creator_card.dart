import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/num_utils.dart';

class CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = (creator['name']?.toString().isNotEmpty == true)
        ? creator['name'].toString() : 'Unknown Creator';
    final niche = (creator['niche']?.toString().trim().isNotEmpty == true)
        ? creator['niche'].toString() : 'Creator';
    final city = creator['city']?.toString() ?? '';

    final igFollowers = toInt(creator['instagram_followers']);
    final ytSubscribers = toInt(creator['youtube_subscribers']);

    final isYouTube = ytSubscribers > igFollowers;
    final followers = isYouTube ? ytSubscribers : igFollowers;
    final platform = isYouTube ? 'YouTube' : 'Instagram';

    String? avatarUrl = isNonEmptyString(creator['avatar_url'])
        ? creator['avatar_url'] as String : null;
    final cs = creator['cached_stats'];
    if (cs is Map) {
      final ig = cs['instagram'];
      final yt = cs['youtube'];
      final candidate = (ig is Map ? ig['profile_picture'] : null) ??
          (yt is Map ? yt['thumbnail'] : null);
      if (isNonEmptyString(candidate)) avatarUrl = candidate as String;
    }

    final startingPrice = toInt(creator['min_budget']);
    final isVerified = creator['verified'] == true;
    final hasBoth = creator['instagram_username'] != null &&
        creator['youtube_channel_id'] != null;

    final engagement = toDouble(creator['engagement_rate']);
    final avgViews = toInt(creator['avg_views']);
    final responseHours = toInt(creator['response_time_hours']);

    final platformColor = isYouTube ? AppColors.youtube : AppColors.instagram;
    final platformIcon = isYouTube
        ? Icons.play_circle_rounded : Icons.camera_alt_rounded;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                                  errorBuilder: (_, __, ___) => _avatarFallback(name),
                                )
                              : _avatarFallback(name),
                        ),
                      ),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 15,
                                  color: Color(0xFF1D9BF0)),
                            ],
                            if (hasBoth) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Multi',
                                  style: TextStyle(fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                            if (creator['match_score'] != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded,
                                        size: 9, color: Colors.white),
                                    const SizedBox(width: 2.5),
                                    Text(
                                      '${(toDouble(creator['match_score']) * 100).toStringAsFixed(0)}% Match',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          city.isNotEmpty ? '$niche • $city' : niche,
                          style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatPill(
                              icon: platformIcon,
                              iconColor: platformColor,
                              value: _fmtNumber(followers),
                              label: platform,
                            ),
                            const SizedBox(width: 8),
                            if (startingPrice > 0)
                              _StatPill(
                                icon: Icons.currency_rupee_rounded,
                                iconColor: AppColors.success,
                                value: _fmtBudget(startingPrice),
                                label: 'from',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textHint),
                ],
              ),

              // Analytics strip — surfaced to brands so they can compare
              // creators at a glance without opening every profile.
              if (engagement > 0 || avgViews > 0 || responseHours > 0) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (engagement > 0)
                      Expanded(
                        child: _MetricCell(
                          icon: Icons.trending_up_rounded,
                          color: _engagementColor(engagement),
                          value: '${engagement.toStringAsFixed(1)}%',
                          label: 'Engagement',
                        ),
                      ),
                    if (avgViews > 0)
                      Expanded(
                        child: _MetricCell(
                          icon: Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          value: _fmtNumber(avgViews),
                          label: 'Avg views',
                        ),
                      ),
                    if (responseHours > 0)
                      Expanded(
                        child: _MetricCell(
                          icon: Icons.bolt_rounded,
                          color: const Color(0xFFF59E0B),
                          value: _fmtResponse(responseHours),
                          label: 'Replies',
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
      ),
    ),
  );

  Color _engagementColor(double r) {
    if (r >= 5) return AppColors.success;
    if (r >= 2) return const Color(0xFFF59E0B);
    return AppColors.textHint;
  }

  String _fmtResponse(int hours) {
    if (hours <= 1) return '<1h';
    if (hours < 24) return '${hours}h';
    final d = hours ~/ 24;
    return '${d}d';
  }

  String _fmtNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  String _fmtBudget(int amount) {
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

class _MetricCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
      ],
    );
  }
}
