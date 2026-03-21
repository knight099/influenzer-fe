import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/instagram_auth_webview.dart';
import '../data/user_profile_repository.dart';
import '../data/creator_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../wallet/data/payment_repository.dart';

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
    if (state == AppLifecycleState.resumed) {
      ref.read(userProfileRepositoryProvider).refreshStats().then((_) {
        ref.invalidate(userProfileProvider);
      }).catchError((_) { ref.invalidate(userProfileProvider); });
    }
  }

  Future<void> _launchInstagramOAuth() async {
    final result = await Navigator.of(context).push<InstagramAuthResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => InstagramAuthWebView.instagram(),
      ),
    );

    if (!mounted) return;

    if (result?.success == true) {
      try {
        await ref.read(authControllerProvider.notifier).connectSocial(
          'instagram',
          result!.code!,
          redirectUri: 'https://qrdba2mpab.ap-south-1.awsapprunner.com/callback/',
        );
        await ref.read(userProfileRepositoryProvider).refreshStats();
        ref.invalidate(userProfileProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Instagram connected successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    } else if (result?.error != null && result!.error != 'Cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${result.error}'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _launchYouTubeOAuth() async {
    if (!kIsWeb) {
      await ref.read(authControllerProvider.notifier).connectYouTube();
      if (mounted) {
        ref.read(userProfileRepositoryProvider).refreshStats().then((_) {
          ref.invalidate(userProfileProvider);
        });
      }
    } else {
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

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: ${next.error}')),
        );
      } else if (next is AsyncData && !next.isLoading && previous?.isLoading == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected successfully!')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Failed to load profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(userProfileProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            // Hero header
            SliverToBoxAdapter(child: _CreatorHero(profile: profile)),

            // Stats cards (if connected)
            if (profile.youtubeConnected || profile.instagramConnected)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _PlatformStatsRow(profile: profile),
                ),
              ),

            // YouTube card
            if (profile.youtubeConnected)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _PlatformCard(
                    title: 'YouTube',
                    icon: Icons.play_circle_rounded,
                    gradient: AppColors.youtubeGradient,
                    hasError: profile.youtubeError != null,
                    onReconnect: _launchYouTubeOAuth,
                    onRefresh: () async {
                      await ref.read(userProfileRepositoryProvider).refreshStats();
                      ref.invalidate(userProfileProvider);
                    },
                    child: profile.youtubeStats != null
                        ? _YouTubeStatsContent(stats: profile.youtubeStats!)
                        : const _StatsPlaceholder(),
                  ),
                ),
              ),

            // Instagram card
            if (profile.instagramConnected)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _PlatformCard(
                    title: 'Instagram',
                    icon: Icons.camera_alt_rounded,
                    gradient: AppColors.instagramGradient,
                    hasError: profile.instagramError != null,
                    onReconnect: _launchInstagramOAuth,
                    onRefresh: () async {
                      await ref.read(userProfileRepositoryProvider).refreshStats();
                      ref.invalidate(userProfileProvider);
                    },
                    child: profile.instagramStats != null
                        ? _InstagramStatsContent(stats: profile.instagramStats!)
                        : const _StatsPlaceholder(),
                  ),
                ),
              ),

            // Linked accounts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Linked Accounts'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _LinkedAccountsCard(
                  profile: profile,
                  onConnectYouTube: _launchYouTubeOAuth,
                  onConnectInstagram: _launchInstagramOAuth,
                ),
              ),
            ),

            // Profile Details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Profile Details'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _ProfileDetailsCard(profile: profile, ref: ref),
              ),
            ),

            // Bank Account
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Payment Details'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _BankAccountCard(ref: ref),
              ),
            ),

            // Settings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Settings'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                child: _SettingsCard(ref: ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _CreatorHero extends StatelessWidget {
  final UserProfile profile;
  const _CreatorHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.name ?? profile.email.split('@').first;
    final isSubscribed = profile.subscriptionStatus == 'ACTIVE';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover
        Container(
          height: 160,
          decoration: const BoxDecoration(
            gradient: AppColors.brandGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20, right: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -10, left: 20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content below cover
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile.avatarUrl != null
                          ? Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _AvatarFallback(name: name),
                            )
                          : _AvatarFallback(name: name),
                    ),
                  ),
                  const Spacer(),
                  // Sub badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSubscribed ? AppColors.successLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSubscribed ? AppColors.success.withOpacity(0.3) : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSubscribed ? Icons.verified_rounded : Icons.bolt_rounded,
                          size: 13,
                          color: isSubscribed ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isSubscribed ? 'Pro Creator' : 'Free Plan',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSubscribed ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.email,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Platform stats row ────────────────────────────────────────────────────────

class _PlatformStatsRow extends StatelessWidget {
  final UserProfile profile;
  const _PlatformStatsRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = <_StatSummary>[];

    if (profile.youtubeConnected && profile.youtubeStats != null) {
      final s = profile.youtubeStats!;
      items.add(_StatSummary(
        icon: Icons.play_circle_rounded,
        color: AppColors.youtube,
        label: 'Subscribers',
        value: _fmt(s.subscriberCount),
      ));
    }
    if (profile.instagramConnected && profile.instagramStats != null) {
      final s = profile.instagramStats!;
      items.add(_StatSummary(
        icon: Icons.camera_alt_rounded,
        color: AppColors.instagram,
        label: 'Followers',
        value: _fmt(s.followersCount),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children: items
          .map((item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == items.last ? 0 : 12,
                  ),
                  child: _StatSummaryTile(item: item),
                ),
              ))
          .toList(),
    );
  }

  String _fmt(String? value) {
    if (value == null) return '0';
    final n = int.tryParse(value) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatSummary {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatSummary({required this.icon, required this.color, required this.label, required this.value});
}

class _StatSummaryTile extends StatelessWidget {
  final _StatSummary item;
  const _StatSummaryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Platform card ─────────────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final bool hasError;
  final VoidCallback onReconnect;
  final VoidCallback onRefresh;
  final Widget child;

  const _PlatformCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.hasError,
    required this.onReconnect,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Error state
          if (hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Stats unavailable. Please reconnect.',
                          style: TextStyle(fontSize: 13, color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onReconnect,
                      icon: const Icon(Icons.link_rounded, size: 16),
                      label: Text('Reconnect $title'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _YouTubeStatsContent extends StatelessWidget {
  final YouTubeStats stats;
  const _YouTubeStatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Channel row
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: stats.thumbnail != null
                  ? Image.network(
                      stats.thumbnail!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _YouTubePlaceholder(),
                    )
                  : _YouTubePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.channelTitle ?? 'YouTube Channel',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  if (stats.channelUrl != null)
                    Text(
                      stats.channelUrl!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatItem(value: _fmt(stats.subscriberCount), label: 'Subscribers', color: AppColors.youtube),
            _divider(),
            _StatItem(value: _fmt(stats.viewCount), label: 'Total Views', color: AppColors.textPrimary),
            _divider(),
            _StatItem(value: _fmt(stats.videoCount), label: 'Videos', color: AppColors.textPrimary),
          ],
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 8));

  String _fmt(String? v) {
    if (v == null) return '0';
    final n = int.tryParse(v) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _YouTubePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(color: AppColors.youtubeLight, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.play_circle_rounded, color: AppColors.youtube, size: 28),
    );
  }
}

class _InstagramStatsContent extends StatelessWidget {
  final InstagramStats stats;
  const _InstagramStatsContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ClipOval(
              child: stats.profilePictureUrl != null
                  ? Image.network(
                      stats.profilePictureUrl!,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InstagramPlaceholder(),
                    )
                  : _InstagramPlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${stats.username ?? 'instagram'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  if (stats.biography != null && stats.biography!.isNotEmpty)
                    Text(
                      stats.biography!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _StatItem(value: _fmt(stats.followersCount), label: 'Followers', color: AppColors.instagram),
            _divider(),
            _StatItem(value: _fmt(stats.followingCount), label: 'Following', color: AppColors.textPrimary),
            _divider(),
            _StatItem(value: _fmt(stats.mediaCount), label: 'Posts', color: AppColors.textPrimary),
          ],
        ),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: 8));

  String _fmt(String? v) {
    if (v == null) return '0';
    final n = int.tryParse(v) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _InstagramPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52, height: 52,
      decoration: const BoxDecoration(
        gradient: AppColors.instagramGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatsPlaceholder extends StatelessWidget {
  const _StatsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.sync_rounded, color: AppColors.textHint, size: 16),
        SizedBox(width: 8),
        Text(
          'Tap refresh to load stats',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Linked accounts ───────────────────────────────────────────────────────────

class _LinkedAccountsCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onConnectYouTube;
  final VoidCallback onConnectInstagram;

  const _LinkedAccountsCard({
    required this.profile,
    required this.onConnectYouTube,
    required this.onConnectInstagram,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.play_circle_rounded,
            gradient: AppColors.youtubeGradient,
            title: 'YouTube',
            subtitle: profile.youtubeConnected
                ? (profile.youtubeChannelName ?? 'Connected')
                : 'Tap to connect',
            isConnected: profile.youtubeConnected,
            onConnect: profile.youtubeConnected ? null : onConnectYouTube,
            showDivider: true,
          ),
          _AccountRow(
            icon: Icons.camera_alt_rounded,
            gradient: AppColors.instagramGradient,
            title: 'Instagram',
            subtitle: profile.instagramConnected
                ? (profile.instagramUsername ?? 'Connected')
                : 'Tap to connect',
            isConnected: profile.instagramConnected,
            onConnect: profile.instagramConnected ? null : onConnectInstagram,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final bool isConnected;
  final VoidCallback? onConnect;
  final bool showDivider;

  const _AccountRow({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.isConnected,
    required this.showDivider,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onConnect,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isConnected ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                isConnected
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Connected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Connect',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}

// ── Profile Details ───────────────────────────────────────────────────────────

class _ProfileDetailsCard extends StatelessWidget {
  final UserProfile profile;
  final WidgetRef ref;
  const _ProfileDetailsCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasBio = profile.bio?.isNotEmpty == true;
    final hasLanguages = profile.languages?.isNotEmpty == true;
    final hasCategories = profile.contentCategories?.isNotEmpty == true;
    final hasBrands = profile.pastBrands?.isNotEmpty == true;
    final hasRateCard = profile.rateCard?.isNotEmpty == true;
    final hasSocialLinks = profile.socialLinks?.isNotEmpty == true;
    final hasAnyData = hasBio || hasLanguages || hasCategories || hasBrands ||
        hasRateCard || hasSocialLinks || (profile.yearsExperience > 0) ||
        profile.city?.isNotEmpty == true || profile.minBudget > 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Creator Profile',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('Visible to brands when they view your profile',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasAnyData ? 'Edit' : 'Add',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!hasAnyData) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  const Text(
                    'Add your professional details to attract more brand deals',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditSheet(context),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Complete Your Profile'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasBio) ...[
                    Text(profile.bio!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      if (profile.city?.isNotEmpty == true)
                        _InfoChip(icon: Icons.location_on_rounded, label: profile.city!, color: AppColors.primary),
                      if (profile.yearsExperience > 0)
                        _InfoChip(icon: Icons.work_rounded,
                            label: '${profile.yearsExperience}y exp', color: const Color(0xFF0EA5E9)),
                      if (profile.minBudget > 0)
                        _InfoChip(icon: Icons.currency_rupee_rounded,
                            label: 'From ₹${profile.minBudget.toStringAsFixed(0)}',
                            color: AppColors.success),
                    ],
                  ),
                  if (hasLanguages) ...[
                    const SizedBox(height: 10),
                    Text('Languages',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (profile.languages ?? '').split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((l) => _Tag(label: l.trim()))
                          .toList(),
                    ),
                  ],
                  if (hasCategories) ...[
                    const SizedBox(height: 10),
                    Text('Content Categories',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (profile.contentCategories ?? '').split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((c) => _Tag(label: c.trim(), color: AppColors.primaryLight, textColor: AppColors.primary))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        profile: profile,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(userProfileProvider);
        },
        creatorRepo: ref.read(creatorRepositoryProvider),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Tag({required this.label, this.color = const Color(0xFFF1F5F9), this.textColor = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditProfileSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _bioCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _categoriesCtrl = TextEditingController();
  final _brandsCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _minBudgetCtrl = TextEditingController();
  // Rate card
  final _perPostCtrl = TextEditingController();
  final _perReelCtrl = TextEditingController();
  final _perVideoCtrl = TextEditingController();
  // Social links
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bioCtrl.text = p.bio ?? '';
    _langCtrl.text = p.languages ?? '';
    _expCtrl.text = p.yearsExperience > 0 ? p.yearsExperience.toString() : '';
    _categoriesCtrl.text = p.contentCategories ?? '';
    _brandsCtrl.text = p.pastBrands ?? '';
    _cityCtrl.text = p.city ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _minBudgetCtrl.text = p.minBudget > 0 ? p.minBudget.toStringAsFixed(0) : '';
    final rc = p.rateCard ?? {};
    _perPostCtrl.text = rc['per_post']?.toString() ?? '';
    _perReelCtrl.text = rc['per_reel']?.toString() ?? '';
    _perVideoCtrl.text = rc['per_video']?.toString() ?? '';
    final sl = p.socialLinks ?? {};
    _twitterCtrl.text = sl['twitter']?.toString() ?? '';
    _linkedinCtrl.text = sl['linkedin']?.toString() ?? '';
    _websiteCtrl.text = sl['website']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final c in [_bioCtrl, _langCtrl, _expCtrl, _categoriesCtrl, _brandsCtrl,
        _cityCtrl, _phoneCtrl, _minBudgetCtrl, _perPostCtrl, _perReelCtrl, _perVideoCtrl,
        _twitterCtrl, _linkedinCtrl, _websiteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final rateCard = <String, dynamic>{};
      if (_perPostCtrl.text.trim().isNotEmpty) rateCard['per_post'] = double.tryParse(_perPostCtrl.text.trim()) ?? 0;
      if (_perReelCtrl.text.trim().isNotEmpty) rateCard['per_reel'] = double.tryParse(_perReelCtrl.text.trim()) ?? 0;
      if (_perVideoCtrl.text.trim().isNotEmpty) rateCard['per_video'] = double.tryParse(_perVideoCtrl.text.trim()) ?? 0;

      final socialLinks = <String, dynamic>{};
      if (_twitterCtrl.text.trim().isNotEmpty) socialLinks['twitter'] = _twitterCtrl.text.trim();
      if (_linkedinCtrl.text.trim().isNotEmpty) socialLinks['linkedin'] = _linkedinCtrl.text.trim();
      if (_websiteCtrl.text.trim().isNotEmpty) socialLinks['website'] = _websiteCtrl.text.trim();

      await widget.creatorRepo.updateCreatorProfile({
        'bio': _bioCtrl.text.trim(),
        'languages': _langCtrl.text.trim(),
        'years_experience': int.tryParse(_expCtrl.text.trim()) ?? 0,
        'content_categories': _categoriesCtrl.text.trim(),
        'past_brands': _brandsCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'min_budget': double.tryParse(_minBudgetCtrl.text.trim()) ?? 0,
        if (rateCard.isNotEmpty) 'rate_card': rateCard,
        if (socialLinks.isNotEmpty) 'social_links': socialLinks,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Profile',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Brands see this when they view your profile',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Bio', _bioCtrl, 'Tell brands about yourself and your content style',
                        maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('City', _cityCtrl, 'e.g. Mumbai')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Years of Experience', _expCtrl, 'e.g. 3',
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('Phone', _phoneCtrl, '+91 9876543210',
                            keyboardType: TextInputType.phone)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Min Budget (₹)', _minBudgetCtrl, 'e.g. 5000',
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Languages', _langCtrl, 'e.g. Hindi, English, Tamil (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Content Categories', _categoriesCtrl,
                        'e.g. Lifestyle, Tech, Food (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Past Brand Collaborations', _brandsCtrl,
                        'e.g. Nike, Myntra, boAt (comma-separated)'),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Rate Card', Icons.monetization_on_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildField('Per Post (₹)', _perPostCtrl, 'e.g. 5000',
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Per Reel (₹)', _perReelCtrl, 'e.g. 8000',
                            keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField('Per Video (₹)', _perVideoCtrl, 'e.g. 15000',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Social Links', Icons.link_rounded),
                    const SizedBox(height: 12),
                    _buildField('Twitter / X', _twitterCtrl, 'https://twitter.com/yourhandle',
                        keyboardType: TextInputType.url),
                    const SizedBox(height: 12),
                    _buildField('LinkedIn', _linkedinCtrl, 'https://linkedin.com/in/yourprofile',
                        keyboardType: TextInputType.url),
                    const SizedBox(height: 12),
                    _buildField('Website / Portfolio', _websiteCtrl, 'https://yourwebsite.com',
                        keyboardType: TextInputType.url),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Profile'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── Bank Account ──────────────────────────────────────────────────────────────

class _BankAccountCard extends StatefulWidget {
  final WidgetRef ref;
  const _BankAccountCard({required this.ref});

  @override
  State<_BankAccountCard> createState() => _BankAccountCardState();
}

class _BankAccountCardState extends State<_BankAccountCard> {
  Map<String, dynamic>? _bankAccount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBankAccount();
  }

  Future<void> _loadBankAccount() async {
    final account = await widget.ref.read(paymentRepositoryProvider).getBankAccount();
    if (mounted) setState(() { _bankAccount = account; _loading = false; });
  }

  void _showAddBankSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBankAccountSheet(
        existing: _bankAccount,
        onSaved: () {
          Navigator.pop(context);
          _loadBankAccount();
        },
        paymentRepo: widget.ref.read(paymentRepositoryProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: _loading
          ? const Center(child: SizedBox(height: 40, child: CircularProgressIndicator(strokeWidth: 2)))
          : _bankAccount == null
              ? _EmptyBankAccount(onAdd: _showAddBankSheet)
              : _BankAccountInfo(account: _bankAccount!, onEdit: _showAddBankSheet),
    );
  }
}

class _EmptyBankAccount extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBankAccount({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 12),
        const Text(
          'No bank account added',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add your bank account to receive payments from brands',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Bank Account'),
          ),
        ),
      ],
    );
  }
}

class _BankAccountInfo extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onEdit;
  const _BankAccountInfo({required this.account, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = account['account_holder_name'] ?? '';
    final number = account['account_number'] ?? '';
    final ifsc = account['ifsc'] ?? '';
    final bank = account['bank_name'] ?? '';
    final isLinked = account['is_linked'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isLinked ? AppColors.successLight : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: isLinked ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (bank.isNotEmpty)
                    Text(bank, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _BankDetailRow(label: 'Account No.', value: number),
              const SizedBox(height: 8),
              _BankDetailRow(label: 'IFSC', value: ifsc),
              if (isLinked) ...[
                const SizedBox(height: 8),
                _BankDetailRow(
                  label: 'Status',
                  value: 'Verified',
                  valueColor: AppColors.success,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _BankDetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _AddBankAccountSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  final PaymentRepository paymentRepo;

  const _AddBankAccountSheet({this.existing, required this.onSaved, required this.paymentRepo});

  @override
  State<_AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<_AddBankAccountSheet> {
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e['account_holder_name'] ?? '';
      _bankCtrl.text = e['bank_name'] ?? '';
      _ifscCtrl.text = e['ifsc'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final account = _accountCtrl.text.trim();
    final ifsc = _ifscCtrl.text.trim().toUpperCase();

    if (name.isEmpty || account.isEmpty || ifsc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.paymentRepo.saveBankAccount(
        accountHolderName: name,
        accountNumber: account,
        ifsc: ifsc,
        bankName: _bankCtrl.text.trim(),
      );
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bank Account Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your bank account details are securely stored and used to transfer payments.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildField('Account Holder Name *', _nameCtrl, 'Full name as on bank account'),
            const SizedBox(height: 12),
            _buildField('Account Number *', _accountCtrl, 'Enter your account number',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField('IFSC Code *', _ifscCtrl, 'e.g. SBIN0001234',
                textCapitalization: TextCapitalization.characters),
            const SizedBox(height: 12),
            _buildField('Bank Name', _bankCtrl, 'e.g. State Bank of India (optional)'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Bank Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── Settings ──────────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.primary,
            title: 'Notifications',
            subtitle: 'View your alerts',
            showDivider: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Help & Support',
            subtitle: 'FAQs, contact us',
            showDivider: true,
            onTap: () => _showHelpSupport(context),
          ),
          _SettingsRow(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'About',
            subtitle: 'Version 1.0.0',
            showDivider: true,
            onTap: () => _showAbout(context),
          ),
          _SettingsRow(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            titleColor: AppColors.error,
            showDivider: false,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: titleColor ?? AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: titleColor ?? AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 160, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _box(160, 20),
              const SizedBox(height: 8),
              _box(120, 14),
              const SizedBox(height: 24),
              _box(double.infinity, 80, radius: 20),
              const SizedBox(height: 16),
              _box(double.infinity, 80, radius: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _box(double w, double h, {double radius = 8}) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Help & Support sheet ──────────────────────────────────────────────────────

void _showHelpSupport(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HelpSupportSheet(),
  );
}

class _HelpSupportSheet extends StatefulWidget {
  const _HelpSupportSheet();

  @override
  State<_HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<_HelpSupportSheet> {
  int? _expanded;

  static const _faqs = [
    (
      q: 'How do I connect my Instagram or YouTube account?',
      a: 'Go to Profile → Linked Accounts and tap on the platform you want to connect. You\'ll be redirected to authenticate with that platform.',
    ),
    (
      q: 'How do I apply for a campaign?',
      a: 'Browse campaigns in the Jobs tab. Open a campaign that interests you and tap "Apply Now". You\'ll need an active subscription to apply.',
    ),
    (
      q: 'When will I get paid for a completed campaign?',
      a: 'Payments are released by the brand after you submit proof of work and it gets approved. Funds are credited to your wallet within 2–3 business days.',
    ),
    (
      q: 'How do I upgrade to Pro?',
      a: 'Go to Jobs → tap any campaign → "Apply Now" will prompt you to subscribe. Choose a plan that suits you and complete the payment via Razorpay.',
    ),
    (
      q: 'Can I cancel my subscription?',
      a: 'Yes. Contact our support team at support@influenzer.in and we\'ll process your cancellation within 24 hours.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find answers or reach out to us',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // FAQs
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_faqs.length, (i) {
                    final faq = _faqs[i];
                    final isOpen = _expanded == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.primaryLight : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOpen ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _expanded = isOpen ? null : i),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq.q,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isOpen ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    size: 20,
                                    color: isOpen ? AppColors.primary : AppColors.textHint,
                                  ),
                                ],
                              ),
                              if (isOpen) ...[
                                const SizedBox(height: 10),
                                Text(
                                  faq.a,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Contact section
                  const Text(
                    'Still need help?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _ContactTile(
                    icon: Icons.email_rounded,
                    iconColor: AppColors.primary,
                    title: 'Email Support',
                    subtitle: 'support@influenzer.in',
                    onTap: () async {
                      final uri = Uri(scheme: 'mailto', path: 'support@influenzer.in',
                          query: 'subject=Support Request - Influenzer App');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF25D366),
                    title: 'WhatsApp',
                    subtitle: 'Chat with us on WhatsApp',
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/919999999999?text=Hi+Influenzer+Support');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── About sheet ───────────────────────────────────────────────────────────────

void _showAbout(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          // App icon placeholder
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Influenzer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 1.0.0',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where Brands Meet Creators',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _AboutLink(
                  label: 'Terms of Service',
                  onTap: () async {
                    final uri = Uri.parse('https://influenzer.in/terms');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AboutLink(
                  label: 'Privacy Policy',
                  onTap: () async {
                    final uri = Uri.parse('https://influenzer.in/privacy');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Made with ❤️ in India',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    ),
  );
}

class _AboutLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AboutLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
