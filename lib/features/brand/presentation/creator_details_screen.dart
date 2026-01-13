import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

class CreatorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> creator;

  const CreatorDetailsScreen({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator['name'] ?? 'Unknown Creator';
    final email = creator['email'] ?? '';
    final phone = creator['phone'] ?? '';
    final niche = creator['niche'] ?? 'Creator';
    final city = creator['city'] ?? '';
    
    final instagramUsername = creator['instagram_username'];
    final instagramUrl = creator['instagram_url'];
    final instagramFollowers = creator['instagram_followers'] ?? 0;
    
    final youtubeChannelTitle = creator['youtube_channel_title'];
    final youtubeUrl = creator['youtube_url'];
    final youtubeSubscribers = creator['youtube_subscribers'];
    
    // Get avatar from cached stats
    String? avatarUrl = creator['avatar_url'];
    if (creator['cached_stats'] != null) {
      final cachedStats = creator['cached_stats'];
      if (cachedStats['instagram']?['profile_picture'] != null) {
        avatarUrl = cachedStats['instagram']['profile_picture'];
      } else if (cachedStats['youtube']?['thumbnail'] != null) {
        avatarUrl = cachedStats['youtube']['thumbnail'];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Implement bookmark
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null 
                        ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (niche.toString().isNotEmpty)
                    Text(
                      niche,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  if (city.toString().isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(city, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                ],
              ),
            ),
            
            // Platform Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Instagram Stats
                  if (instagramUsername != null)
                    _PlatformCard(
                      icon: Icons.camera_alt,
                      iconColor: const Color(0xFFE1306C),
                      title: 'Instagram',
                      username: '@$instagramUsername',
                      stats: [
                        _StatItem(
                          label: 'Followers',
                          value: _formatNumber(instagramFollowers),
                        ),
                        if (creator['cached_stats']?['instagram']?['media_count'] != null)
                          _StatItem(
                            label: 'Posts',
                            value: creator['cached_stats']['instagram']['media_count'].toString(),
                          ),
                      ],
                      onTap: instagramUrl != null 
                          ? () => _launchUrl(instagramUrl) 
                          : null,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // YouTube Stats
                  if (youtubeChannelTitle != null)
                    _PlatformCard(
                      icon: Icons.play_circle_filled,
                      iconColor: const Color(0xFFFF0000),
                      title: 'YouTube',
                      username: youtubeChannelTitle,
                      stats: [
                        _StatItem(
                          label: 'Subscribers',
                          value: _formatNumber(int.tryParse(youtubeSubscribers?.toString() ?? '0') ?? 0),
                        ),
                        if (creator['cached_stats']?['youtube']?['video_count'] != null)
                          _StatItem(
                            label: 'Videos',
                            value: creator['cached_stats']['youtube']['video_count'].toString(),
                          ),
                      ],
                      onTap: youtubeUrl != null 
                          ? () => _launchUrl(youtubeUrl) 
                          : null,
                    ),
                ],
              ),
            ),
            
            // Contact Information
            if (email.isNotEmpty || phone.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (email.isNotEmpty)
                              _ContactItem(
                                icon: Icons.email,
                                label: 'Email',
                                value: email,
                                onTap: () => _launchUrl('mailto:$email'),
                              ),
                            if (email.isNotEmpty && phone.isNotEmpty)
                              const Divider(height: 24),
                            if (phone.isNotEmpty)
                              _ContactItem(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: phone,
                                onTap: () => _launchUrl('tel:$phone'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Chat Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to chat with creator info
                    context.push('/chat-room', extra: {
                      'recipient_id': creator['id'],
                      'recipient_name': name,
                      'recipient_avatar': avatarUrl,
                    });
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Invite to Campaign Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to campaign creation with pre-selected creator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Campaign invitation coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.campaign),
                  label: const Text('Invite'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _PlatformCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String username;
  final List<_StatItem> stats;
  final VoidCallback? onTap;

  const _PlatformCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.username,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          username,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.open_in_new, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
