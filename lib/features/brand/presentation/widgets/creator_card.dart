import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;
  
  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator['name'] ?? 'Unknown Creator';
    final niche = creator['niche']?.toString().trim().isEmpty == true 
        ? 'Creator' 
        : creator['niche'];
    final city = creator['city'];
    
    // Determine primary platform and follower count
    final instagramFollowers = creator['instagram_followers'] ?? 0;
    final youtubeSubscribers = int.tryParse(creator['youtube_subscribers']?.toString() ?? '0') ?? 0;
    
    int followers;
    String platform;
    if (instagramFollowers > youtubeSubscribers) {
      followers = instagramFollowers;
      platform = 'Instagram';
    } else if (youtubeSubscribers > 0) {
      followers = youtubeSubscribers;
      platform = 'YouTube';
    } else {
      followers = instagramFollowers;
      platform = 'Instagram';
    }
    
    // Use avatar from cached stats or fallback to avatar_url
    String? avatarUrl = creator['avatar_url'];
    if (creator['cached_stats'] != null) {
      final cachedStats = creator['cached_stats'];
      if (cachedStats['instagram'] != null && cachedStats['instagram']['profile_picture'] != null) {
        avatarUrl = cachedStats['instagram']['profile_picture'];
      } else if (cachedStats['youtube'] != null && cachedStats['youtube']['thumbnail'] != null) {
        avatarUrl = cachedStats['youtube']['thumbnail'];
      }
    }
    
    // Calculate engagement rate (placeholder - would need actual data)
    final engagement = 0.0;
    
    // Get minimum budget from API (default to 0 if not present)
    final startingPrice = creator['min_budget'] ?? 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.push('/creator-details', extra: creator);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 30, color: Colors.grey) : null,
              ),
              const SizedBox(width: 16),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (creator['verified'] == true)
                          const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ),
                    Text(
                      niche is String 
                          ? '$niche${city != null && city.toString().isNotEmpty ? ' • $city' : ''}'
                          : city != null && city.toString().isNotEmpty ? city : 'Creator',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stat(label: platform, value: _formatNumber(followers)),
                        if (creator['instagram_username'] != null && creator['youtube_channel_id'] != null)
                          const SizedBox(width: 16),
                        if (creator['instagram_username'] != null && creator['youtube_channel_id'] != null)
                          const Icon(Icons.link, size: 14, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '₹$startingPrice',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'starting',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {
                      // TODO: Implement bookmark functionality
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
