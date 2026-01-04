import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/user_profile_repository.dart';
import '../../auth/application/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app returns from background (e.g., after OAuth), refresh profile
    if (state == AppLifecycleState.resumed) {
      debugPrint('[Profile] App resumed, refreshing stats and profile...');
      // First refresh stats with new tokens, then reload profile
      ref.read(userProfileRepositoryProvider).refreshStats().then((_) {
        debugPrint('[Profile] Stats refreshed, now reloading profile...');
        ref.invalidate(userProfileProvider);
      }).catchError((error) {
        debugPrint('[Profile] Error refreshing stats: $error');
        // Still reload profile even if refresh fails
        ref.invalidate(userProfileProvider);
      });
    }
  }

  // Helper to launch Instagram OAuth
  Future<void> _launchInstagramOAuth() async {
    const clientId = '816744758013078';
    final redirectUri = 'https://influenzer.onrender.com/callback/';
    const scope = 'instagram_business_basic,instagram_business_manage_messages,instagram_business_manage_comments,instagram_business_content_publish,instagram_business_manage_insights';
    const state = 'instagram';
    
    final uri = Uri.https('www.instagram.com', '/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': scope,
      'response_type': 'code',
      'state': state,
      'force_reauth': 'true',
    });
    
    final url = uri.toString();
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_self');
    }
  }

  // Helper to launch YouTube OAuth
  Future<void> _launchYouTubeOAuth() async {
    if (!kIsWeb) {
      // Use Native Google Sign-In on Mobile
      await ref.read(authControllerProvider.notifier).connectYouTube();
      // After connection attempt finishes, refresh stats explicitly
      // This handles the race condition where app resume happens before connection completion
      if (mounted) {
         ref.read(userProfileRepositoryProvider).refreshStats().then((_) {
           ref.invalidate(userProfileProvider);
         });
      }
    } else {
      // Use Manual Web Flow
      const clientId = '47008398696-bsn5162rp1cl2nie455mmr6vu10fvcog.apps.googleusercontent.com';
      const redirectUri = 'http://localhost:8081/callback';
      const scope = 'email profile https://www.googleapis.com/auth/youtube.readonly';
      const state = 'youtube';
      
      final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scope,
        'access_type': 'offline',
        'state': state,
      });
      
      launchUrl(Uri.parse(uri.toString()), webOnlyWindowName: '_self');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    
    // Listen for auth errors/success
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection Failed: ${next.error}')),
        );
      } else if (next is AsyncData && !next.isLoading && previous?.isLoading == true) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected Successfully!')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Profile Header
              _buildProfileHeader(profile),
              const SizedBox(height: 32),
              
              // YouTube Stats Section (if connected)
              // YouTube Stats Section (if connected)
              if (profile.youtubeConnected) ...[
                _buildSectionTitleWithAction(
                  'YouTube Stats',
                  onRefresh: () async {
                    await ref.read(userProfileRepositoryProvider).refreshStats();
                    ref.invalidate(userProfileProvider);
                  },
                ),
                const SizedBox(height: 12),
                if (profile.youtubeError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Failed to refresh stats. Please reconnect your account.',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _launchYouTubeOAuth,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reconnect YouTube'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (profile.youtubeStats != null)
                  _buildYouTubeStatsCard(profile.youtubeStats!)
                else 
                   const Center(child: Text('Click refresh to load stats', style: TextStyle(color: Colors.grey))),

                const SizedBox(height: 24),
              ],
              
              // Instagram Stats Section (if connected)
              if (profile.instagramConnected) ...[
                _buildSectionTitleWithAction(
                  'Instagram Stats',
                  onRefresh: () async {
                    await ref.read(userProfileRepositoryProvider).refreshStats();
                    ref.invalidate(userProfileProvider);
                  },
                ),
                const SizedBox(height: 12),
                if (profile.instagramError != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Failed to refresh stats. Please reconnect your account.',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _launchInstagramOAuth,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reconnect Instagram'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE1306C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (profile.instagramStats != null)
                  _buildInstagramStatsCard(profile.instagramStats!)
                else 
                   const Center(child: Text('Click refresh to load stats', style: TextStyle(color: Colors.grey))),

                const SizedBox(height: 24),
              ],
              
              // Linked Accounts Section
              _buildSectionTitle('Linked Accounts'),
              const SizedBox(height: 12),
              _buildLinkedAccountsCard(context, profile),
              const SizedBox(height: 24),
              
              // Settings Section
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              _buildSettingsCard(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white.withOpacity(0.2),
            ),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
          ),
          const SizedBox(width: 20),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? profile.email.split('@').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionTitleWithAction(String title, {required VoidCallback onRefresh}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: AppColors.primary),
          tooltip: 'Refresh stats',
        ),
      ],
    );
  }

  Widget _buildYouTubeStatsCard(YouTubeStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Channel info row
          Row(
            children: [
              if (stats.thumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    stats.thumbnail!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.red.withOpacity(0.1),
                      child: const Icon(Icons.play_circle_filled, color: Colors.red),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_filled, color: Colors.red),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.channelTitle ?? 'YouTube Channel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (stats.channelUrl != null)
                      Text(
                        stats.channelUrl!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Subscribers',
                value: _formatNumber(stats.subscriberCount),
                icon: Icons.people,
              ),
              _buildStatItem(
                label: 'Views',
                value: _formatNumber(stats.viewCount),
                icon: Icons.visibility,
              ),
              _buildStatItem(
                label: 'Videos',
                value: _formatNumber(stats.videoCount),
                icon: Icons.video_library,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatNumber(String? value) {
    if (value == null) return '0';
    final num = int.tryParse(value) ?? 0;
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  Widget _buildLinkedAccountsCard(BuildContext context, UserProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAccountTile(
            icon: Icons.play_circle_filled,
            iconColor: Colors.red,
            title: 'YouTube',
            subtitle: profile.youtubeConnected 
                ? (profile.youtubeChannelName ?? 'Connected')
                : 'Not connected',
            isConnected: profile.youtubeConnected,
            onTap: () => context.go('/social-link'),
          ),
          const Divider(height: 1),
          _buildAccountTile(
            icon: Icons.camera_alt,
            iconColor: const Color(0xFFE1306C),
            title: 'Instagram',
            subtitle: profile.instagramConnected 
                ? (profile.instagramUsername ?? 'Connected')
                : 'Not connected',
            isConnected: profile.instagramConnected,
            onTap: () => context.go('/social-link'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 28),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isConnected ? Colors.green : AppColors.textSecondary,
        ),
      ),
      trailing: isConnected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : TextButton(
              onPressed: onTap,
              child: const Text('Connect'),
            ),
      onTap: onTap,
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildInstagramStatsCard(InstagramStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile info row
          Row(
            children: [
              if (stats.profilePictureUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    stats.profilePictureUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.purple, Colors.pink, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.pink, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${stats.username ?? 'Instagram'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (stats.biography != null && stats.biography!.isNotEmpty)
                      Text(
                        stats.biography!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Followers',
                value: _formatNumber(stats.followersCount),
                icon: Icons.people,
              ),
              _buildStatItem(
                label: 'Following',
                value: _formatNumber(stats.followingCount),
                icon: Icons.person_add,
              ),
              _buildStatItem(
                label: 'Posts',
                value: _formatNumber(stats.mediaCount),
                icon: Icons.grid_on,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

