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
      const scope = 'email profile https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/yt-analytics.readonly';
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

            // ── 1. Profile Completion Banner ──
            if (profile.profileComplete < 80)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ProfileCompletionBanner(
                    percent: profile.profileComplete,
                    onComplete: () => _showEditAboutSheet(context, profile),
                  ),
                ),
              ),

            // ── 2. Performance Snapshot ──
            if (profile.totalCampaigns > 0 || profile.completedCampaigns > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _PerformanceSnapshotCard(profile: profile),
                ),
              ),

            // ── 3. Quick Facts Strip ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: _QuickFactsStrip(profile: profile),
              ),
            ),

            // ── 4. About Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _AboutSectionCard(
                  profile: profile,
                  onEdit: () => _showEditAboutSheet(context, profile),
                ),
              ),
            ),

            // ── 5. Rate Card Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _RateCardSectionCard(
                  profile: profile,
                  onEdit: () => _showEditRateCardSheet(context, profile),
                ),
              ),
            ),

            // ── 6. Audience Demographics ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _AudienceDemographicsCard(
                  profile: profile,
                  onEdit: () => _showEditAudienceSheet(context, profile),
                ),
              ),
            ),

            // ── 7. Past Work & Portfolio ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PastWorkCard(
                  profile: profile,
                  onAdd: () => _showEditPastWorkSheet(context, profile),
                ),
              ),
            ),

            // ── 8. Collaboration Preferences ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _CollaborationPrefsCard(
                  profile: profile,
                  onEdit: () => _showEditCollaborationPrefsSheet(context, profile),
                ),
              ),
            ),

            // ── 9. Social Links ──
            if (profile.socialLinks != null && profile.socialLinks!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SocialLinksCard(profile: profile),
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

  // ── Edit sheet launchers ──

  void _showEditAboutSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAboutSheet(
        profile: profile,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(userProfileProvider);
        },
        creatorRepo: ref.read(creatorRepositoryProvider),
      ),
    );
  }

  void _showEditRateCardSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditRateCardSheet(
        profile: profile,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(userProfileProvider);
        },
        creatorRepo: ref.read(creatorRepositoryProvider),
      ),
    );
  }

  void _showEditAudienceSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditAudienceSheet(
        profile: profile,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(userProfileProvider);
        },
        creatorRepo: ref.read(creatorRepositoryProvider),
      ),
    );
  }

  void _showEditPastWorkSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPastWorkSheet(
        profile: profile,
        onSaved: () {
          Navigator.pop(context);
          ref.invalidate(userProfileProvider);
        },
        creatorRepo: ref.read(creatorRepositoryProvider),
      ),
    );
  }

  void _showEditCollaborationPrefsSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCollaborationPrefsSheet(
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
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -10, left: 20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
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
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile.avatarUrl != null
                          ? Image.network(
                              profile.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _AvatarFallback(name: name),
                            )
                          : _AvatarFallback(name: name),
                    ),
                  ),
                  const Spacer(),
                  // Availability badge
                  _AvailabilityBadge(status: profile.availabilityStatus),
                  const SizedBox(width: 8),
                  // Sub badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSubscribed ? AppColors.successLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSubscribed ? AppColors.success.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
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

              // Headline
              if (profile.headline != null && profile.headline!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.headline!,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final String status;
  const _AvailabilityBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'busy':
        color = AppColors.warning;
        label = 'Busy';
        break;
      case 'not_accepting':
        color = AppColors.error;
        label = 'Unavailable';
        break;
      default:
        color = AppColors.success;
        label = 'Available';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
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
        color: item.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                      errorBuilder: (_, _, _) => _YouTubePlaceholder(),
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
                      errorBuilder: (_, _, _) => _InstagramPlaceholder(),
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

// ── Profile Completion Banner ────────────────────────────────────────────────

class _ProfileCompletionBanner extends StatelessWidget {
  final int percent;
  final VoidCallback onComplete;
  const _ProfileCompletionBanner({required this.percent, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profile $percent% complete',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Complete your profile to attract more brands',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Complete Now', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Performance Snapshot Card ─────────────────────────────────────────────────

class _PerformanceSnapshotCard extends StatelessWidget {
  final UserProfile profile;
  const _PerformanceSnapshotCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Performance Snapshot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _PerformanceMetric(
                value: profile.totalCampaigns.toString(),
                label: 'Total\nCampaigns',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _PerformanceMetric(
                value: profile.completedCampaigns.toString(),
                label: 'Completed',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PerformanceMetric(
                value: profile.avgRating > 0 ? profile.avgRating.toStringAsFixed(1) : '-',
                label: 'Avg Rating',
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              _PerformanceMetric(
                value: profile.responseTime ?? '-',
                label: 'Response\nTime',
                color: const Color(0xFF0EA5E9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _PerformanceMetric({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ── Quick Facts Strip ────────────────────────────────────────────────────────

class _QuickFactsStrip extends StatelessWidget {
  final UserProfile profile;
  const _QuickFactsStrip({required this.profile});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (profile.city?.isNotEmpty == true) {
      chips.add(_InfoChip(icon: Icons.location_on_rounded, label: profile.city!, color: AppColors.primary));
    }
    if (profile.yearsExperience > 0) {
      chips.add(_InfoChip(icon: Icons.work_rounded, label: '${profile.yearsExperience}y exp', color: const Color(0xFF0EA5E9)));
    }
    if (profile.languages?.isNotEmpty == true) {
      chips.add(_InfoChip(icon: Icons.language_rounded, label: profile.languages!, color: AppColors.secondary));
    }
    if (profile.minBudget > 0) {
      chips.add(_InfoChip(icon: Icons.currency_rupee_rounded, label: 'From \u20b9${profile.minBudget.toStringAsFixed(0)}', color: AppColors.success));
    }
    if (profile.gender != null && profile.gender!.isNotEmpty) {
      final genderLabel = _genderDisplayLabel(profile.gender!);
      chips.add(_InfoChip(icon: Icons.person_rounded, label: genderLabel, color: AppColors.textSecondary));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  String _genderDisplayLabel(String value) {
    switch (value) {
      case 'male': return 'Male';
      case 'female': return 'Female';
      case 'non_binary': return 'Non-binary';
      case 'prefer_not_to_say': return 'Prefer not to say';
      default: return value;
    }
  }
}

// ── About Section Card ───────────────────────────────────────────────────────

class _AboutSectionCard extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _AboutSectionCard({required this.profile, required this.onEdit});

  @override
  State<_AboutSectionCard> createState() => _AboutSectionCardState();
}

class _AboutSectionCardState extends State<_AboutSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final hasBio = p.bio?.isNotEmpty == true;
    final hasHeadline = p.headline?.isNotEmpty == true;
    final hasCategories = p.contentCategories?.isNotEmpty == true;
    final hasAnyData = hasBio || hasHeadline || hasCategories;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('About', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(hasAnyData ? 'Edit' : 'Add',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                    'Add your bio, headline and content categories to attract more brands',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Add About Info'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasHeadline) ...[
                    Text(p.headline!,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4)),
                    const SizedBox(height: 10),
                  ],
                  if (hasBio) ...[
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        p.bio!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                    if (p.bio!.length > 120)
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _expanded ? 'Show less' : 'Read more',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (hasCategories) ...[
                    const Text('Content Categories',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (p.contentCategories ?? '').split(',')
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
}

// ── Rate Card Section Card ───────────────────────────────────────────────────

class _RateCardSectionCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _RateCardSectionCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final rc = profile.rateCard ?? {};
    final hasRateCard = rc.isNotEmpty;

    final deliverables = <String, String>{
      'per_post': 'Per Post',
      'per_reel': 'Per Reel',
      'per_story': 'Per Story',
      'per_video': 'Per Video',
      'per_carousel': 'Per Carousel',
      'per_live': 'Per Live',
      'per_youtube_integration': 'YT Integration',
      'per_youtube_short': 'YT Short',
    };

    final customPackages = rc['custom_packages'] as List<dynamic>? ?? [];
    final isBarter = rc['per_barter'] == true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Rate Card', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(hasRateCard ? 'Edit' : 'Add',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          if (!hasRateCard) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'Add your rates for different deliverable types so brands can find the right fit',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: deliverables.entries.where((e) {
                      final val = rc[e.key];
                      return val != null && val != 0 && val != '0';
                    }).map((e) {
                      final val = rc[e.key];
                      return _RateChip(label: e.value, amount: '\u20b9${_fmtAmount(val)}');
                    }).toList(),
                  ),
                  if (isBarter) ...[
                    const SizedBox(height: 10),
                    _InfoChip(icon: Icons.swap_horiz_rounded, label: 'Open to Barter', color: AppColors.success),
                  ],
                  if (customPackages.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text('Custom Packages',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 8),
                    ...customPackages.map((pkg) {
                      final p = pkg as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(p['name'] ?? 'Package', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                              if (p['price'] != null)
                                Text('\u20b9${p['price']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtAmount(dynamic val) {
    if (val == null) return '0';
    final n = double.tryParse(val.toString()) ?? 0;
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

class _RateChip extends StatelessWidget {
  final String label;
  final String amount;
  const _RateChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Audience Demographics Card ───────────────────────────────────────────────

class _AudienceDemographicsCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _AudienceDemographicsCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final demo = profile.audienceDemographics;
    final hasData = demo != null && demo.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.people_alt_rounded, color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Audience Demographics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(hasData ? 'Edit' : 'Add',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          if (!hasData) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'Add your audience demographics to help brands understand your reach',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age split
                  if (demo['age_split'] != null) ...[
                    const Text('Age Distribution',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 8),
                    ..._buildAgeBars(demo['age_split'] as Map<String, dynamic>),
                    const SizedBox(height: 14),
                  ],
                  // Gender split
                  if (demo['gender_split'] != null) ...[
                    const Text('Gender Split',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 8),
                    _buildGenderRow(demo['gender_split'] as Map<String, dynamic>),
                    const SizedBox(height: 14),
                  ],
                  // Top cities
                  if (demo['top_cities'] != null && (demo['top_cities'] as String).isNotEmpty) ...[
                    const Text('Top Cities',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (demo['top_cities'] as String).split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((c) => _Tag(label: c.trim()))
                          .toList(),
                    ),
                  ],
                  // Top countries
                  if (demo['top_countries'] != null && (demo['top_countries'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Top Countries',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (demo['top_countries'] as String).split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((c) => _Tag(label: c.trim()))
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

  List<Widget> _buildAgeBars(Map<String, dynamic> ageSplit) {
    final ranges = ['18-24', '25-34', '35-44', '45+'];
    final colors = [AppColors.primary, AppColors.success, AppColors.warning, AppColors.secondary];
    return List.generate(ranges.length, (i) {
      final key = ranges[i];
      final pct = (ageSplit[key] as num?)?.toDouble() ?? 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 44, child: Text(key, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100.0,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(colors[i]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 36, child: Text('${pct.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                textAlign: TextAlign.right)),
          ],
        ),
      );
    });
  }

  Widget _buildGenderRow(Map<String, dynamic> genderSplit) {
    final male = (genderSplit['male'] as num?)?.toDouble() ?? 0;
    final female = (genderSplit['female'] as num?)?.toDouble() ?? 0;
    final other = (genderSplit['other'] as num?)?.toDouble() ?? 0;
    return Row(
      children: [
        _GenderStat(label: 'Male', pct: male, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 12),
        _GenderStat(label: 'Female', pct: female, color: AppColors.secondary),
        const SizedBox(width: 12),
        _GenderStat(label: 'Other', pct: other, color: AppColors.textSecondary),
      ],
    );
  }
}

class _GenderStat extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _GenderStat({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Past Work & Portfolio Card ───────────────────────────────────────────────

class _PastWorkCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onAdd;
  const _PastWorkCard({required this.profile, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final hasPastWork = profile.pastWork.isNotEmpty;
    final hasLegacyBrands = profile.pastBrands?.isNotEmpty == true;
    final hasAny = hasPastWork || hasLegacyBrands;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.work_history_rounded, color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Past Work & Portfolio', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(hasAny ? 'Edit' : 'Add Work',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          if (!hasAny) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'Showcase your past brand collaborations and portfolio to build credibility',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasPastWork) ...[
                    ...profile.pastWork.take(5).map((work) => _PastWorkEntry(work: work)),
                    if (profile.pastWork.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${profile.pastWork.length - 5} more',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                  ],
                  if (!hasPastWork && hasLegacyBrands) ...[
                    const Text('Brand Collaborations',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (profile.pastBrands ?? '').split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((b) => _Tag(label: b.trim(), color: AppColors.warningLight, textColor: AppColors.warning))
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
}

class _PastWorkEntry extends StatelessWidget {
  final Map<String, dynamic> work;
  const _PastWorkEntry({required this.work});

  @override
  Widget build(BuildContext context) {
    final brand = work['brand_name'] ?? 'Brand';
    final deliverable = work['deliverable_type'] ?? '';
    final platform = work['platform'] ?? '';
    final date = work['date'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (deliverable.isNotEmpty || platform.isNotEmpty)
                    Text(
                      [deliverable, platform].where((s) => s.isNotEmpty).join(' \u2022 '),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            if (date.isNotEmpty)
              Text(date, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}

// ── Collaboration Preferences Card ──────────────────────────────────────────

class _CollaborationPrefsCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  const _CollaborationPrefsCard({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final prefs = profile.collaborationPrefs;
    final hasData = prefs != null && prefs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.secondaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.handshake_rounded, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Collaboration Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: Text(hasData ? 'Edit' : 'Add',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
          if (!hasData) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Text(
                'Set your collaboration preferences so brands know what you are open to',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasNonEmpty(prefs, 'preferred_categories')) ...[
                    const Text('Preferred Categories',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (prefs['preferred_categories'] as String).split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((c) => _Tag(label: c.trim(), color: AppColors.primaryLight, textColor: AppColors.primary))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasNonEmpty(prefs, 'content_types')) ...[
                    const Text('Content Types Open To',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (prefs['content_types'] as String).split(',')
                          .where((s) => s.trim().isNotEmpty)
                          .map((c) => _Tag(label: c.trim(), color: AppColors.secondaryLight, textColor: AppColors.secondary))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Toggle indicators
                  Wrap(
                    spacing: 10, runSpacing: 8,
                    children: [
                      if (prefs['barter_open'] == true)
                        _ToggleIndicator(label: 'Barter Open', isActive: true),
                      if (prefs['exclusivity_open'] == true)
                        _ToggleIndicator(label: 'Exclusivity Open', isActive: true),
                      if (profile.willingToTravel)
                        _ToggleIndicator(label: 'Willing to Travel', isActive: true),
                    ],
                  ),
                  if (profile.turnaroundDays > 0) ...[
                    const SizedBox(height: 10),
                    _InfoChip(icon: Icons.timer_rounded, label: '${profile.turnaroundDays}d turnaround', color: const Color(0xFF0EA5E9)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasNonEmpty(Map<String, dynamic> prefs, String key) {
    final val = prefs[key];
    return val != null && val is String && val.isNotEmpty;
  }
}

class _ToggleIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  const _ToggleIndicator({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: isActive ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }
}

// ── Social Links Card ────────────────────────────────────────────────────────

class _SocialLinksCard extends StatelessWidget {
  final UserProfile profile;
  const _SocialLinksCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final links = profile.socialLinks ?? {};
    if (links.isEmpty) return const SizedBox.shrink();

    final entries = <MapEntry<String, IconData>>[];
    if (links['twitter'] != null && (links['twitter'] as String).isNotEmpty) {
      entries.add(const MapEntry('twitter', Icons.alternate_email_rounded));
    }
    if (links['linkedin'] != null && (links['linkedin'] as String).isNotEmpty) {
      entries.add(const MapEntry('linkedin', Icons.business_rounded));
    }
    if (links['website'] != null && (links['website'] as String).isNotEmpty) {
      entries.add(const MapEntry('website', Icons.language_rounded));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Social Links', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          ...entries.map((entry) {
            final url = links[entry.key]?.toString() ?? '';
            return InkWell(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(entry.value, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _linkLabel(entry.key),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(url, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  String _linkLabel(String key) {
    switch (key) {
      case 'twitter': return 'Twitter / X';
      case 'linkedin': return 'LinkedIn';
      case 'website': return 'Website / Portfolio';
      default: return key;
    }
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

// ── Shared widgets ───────────────────────────────────────────────────────────

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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    color: iconColor.withValues(alpha: 0.1),
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

// ══════════════════════════════════════════════════════════════════════════════
// ── EDIT SHEETS ──────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

// ── Edit About Sheet ─────────────────────────────────────────────────────────

class _EditAboutSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditAboutSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditAboutSheet> createState() => _EditAboutSheetState();
}

class _EditAboutSheetState extends State<_EditAboutSheet> {
  final _headlineCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _pinCodeCtrl = TextEditingController();
  final _langCtrl = TextEditingController();
  final _categoriesCtrl = TextEditingController();
  final _nicheCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _minBudgetCtrl = TextEditingController();
  // Social links
  final _twitterCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  String _gender = '';
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _headlineCtrl.text = p.headline ?? '';
    _bioCtrl.text = p.bio ?? '';
    _cityCtrl.text = p.city ?? '';
    _locationCtrl.text = p.location ?? '';
    _pinCodeCtrl.text = p.pinCode ?? '';
    _langCtrl.text = p.languages ?? '';
    _categoriesCtrl.text = p.contentCategories ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _expCtrl.text = p.yearsExperience > 0 ? p.yearsExperience.toString() : '';
    _minBudgetCtrl.text = p.minBudget > 0 ? p.minBudget.toStringAsFixed(0) : '';
    _gender = p.gender ?? '';
    _dateOfBirth = p.dateOfBirth;
    final sl = p.socialLinks ?? {};
    _twitterCtrl.text = sl['twitter']?.toString() ?? '';
    _linkedinCtrl.text = sl['linkedin']?.toString() ?? '';
    _websiteCtrl.text = sl['website']?.toString() ?? '';
  }

  @override
  void dispose() {
    for (final c in [_headlineCtrl, _bioCtrl, _cityCtrl, _locationCtrl, _pinCodeCtrl,
        _langCtrl, _categoriesCtrl, _nicheCtrl, _phoneCtrl, _expCtrl, _minBudgetCtrl,
        _twitterCtrl, _linkedinCtrl, _websiteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final socialLinks = <String, dynamic>{};
      if (_twitterCtrl.text.trim().isNotEmpty) socialLinks['twitter'] = _twitterCtrl.text.trim();
      if (_linkedinCtrl.text.trim().isNotEmpty) socialLinks['linkedin'] = _linkedinCtrl.text.trim();
      if (_websiteCtrl.text.trim().isNotEmpty) socialLinks['website'] = _websiteCtrl.text.trim();

      await widget.creatorRepo.updateCreatorProfile({
        'headline': _headlineCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'pin_code': _pinCodeCtrl.text.trim(),
        'languages': _langCtrl.text.trim(),
        'content_categories': _categoriesCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'years_experience': int.tryParse(_expCtrl.text.trim()) ?? 0,
        'min_budget': double.tryParse(_minBudgetCtrl.text.trim()) ?? 0,
        'gender': _gender,
        if (_dateOfBirth != null) 'date_of_birth': _dateOfBirth!.toIso8601String().split('T').first,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Brands see this on your profile', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Headline', _headlineCtrl, 'e.g. Tech Creator | 500K+ Audience'),
                    const SizedBox(height: 16),
                    _buildField('Bio', _bioCtrl, 'Tell brands about yourself and your content style', maxLines: 3),
                    const SizedBox(height: 16),
                    // Gender dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gender', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender.isEmpty ? null : _gender,
                              hint: const Text('Select gender', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'non_binary', child: Text('Non-binary')),
                                DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                              ],
                              onChanged: (val) => setState(() => _gender = val ?? ''),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Date of birth
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date of Birth', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _dateOfBirth != null
                                  ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                  : 'Select date',
                              style: TextStyle(fontSize: 14, color: _dateOfBirth != null ? AppColors.textPrimary : AppColors.textHint),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('City', _cityCtrl, 'e.g. Mumbai')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Years of Experience', _expCtrl, 'e.g. 3', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Location (full address)', _locationCtrl, 'e.g. Andheri West, Mumbai'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField('PIN Code', _pinCodeCtrl, 'e.g. 400058', keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Phone', _phoneCtrl, '+91 9876543210', keyboardType: TextInputType.phone)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Min Budget (\u20b9)', _minBudgetCtrl, 'e.g. 5000', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildField('Languages', _langCtrl, 'e.g. Hindi, English, Tamil (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Content Categories', _categoriesCtrl, 'e.g. Lifestyle, Tech, Food (comma-separated)'),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Social Links', Icons.link_rounded),
                    const SizedBox(height: 12),
                    _buildField('Twitter / X', _twitterCtrl, 'https://twitter.com/yourhandle', keyboardType: TextInputType.url),
                    const SizedBox(height: 12),
                    _buildField('LinkedIn', _linkedinCtrl, 'https://linkedin.com/in/yourprofile', keyboardType: TextInputType.url),
                    const SizedBox(height: 12),
                    _buildField('Website / Portfolio', _websiteCtrl, 'https://yourwebsite.com', keyboardType: TextInputType.url),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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

// ── Edit Rate Card Sheet ─────────────────────────────────────────────────────

class _EditRateCardSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditRateCardSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditRateCardSheet> createState() => _EditRateCardSheetState();
}

class _EditRateCardSheetState extends State<_EditRateCardSheet> {
  final _perPostCtrl = TextEditingController();
  final _perReelCtrl = TextEditingController();
  final _perStoryCtrl = TextEditingController();
  final _perVideoCtrl = TextEditingController();
  final _perCarouselCtrl = TextEditingController();
  final _perLiveCtrl = TextEditingController();
  final _perYtIntegrationCtrl = TextEditingController();
  final _perYtShortCtrl = TextEditingController();
  bool _perBarter = false;
  List<Map<String, dynamic>> _customPackages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rc = widget.profile.rateCard ?? {};
    _perPostCtrl.text = _valStr(rc['per_post']);
    _perReelCtrl.text = _valStr(rc['per_reel']);
    _perStoryCtrl.text = _valStr(rc['per_story']);
    _perVideoCtrl.text = _valStr(rc['per_video']);
    _perCarouselCtrl.text = _valStr(rc['per_carousel']);
    _perLiveCtrl.text = _valStr(rc['per_live']);
    _perYtIntegrationCtrl.text = _valStr(rc['per_youtube_integration']);
    _perYtShortCtrl.text = _valStr(rc['per_youtube_short']);
    _perBarter = rc['per_barter'] == true;
    final rawPkg = rc['custom_packages'] as List<dynamic>? ?? [];
    _customPackages = rawPkg.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  String _valStr(dynamic val) {
    if (val == null || val == 0 || val == '0') return '';
    return val.toString();
  }

  @override
  void dispose() {
    for (final c in [_perPostCtrl, _perReelCtrl, _perStoryCtrl, _perVideoCtrl,
        _perCarouselCtrl, _perLiveCtrl, _perYtIntegrationCtrl, _perYtShortCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final rateCard = <String, dynamic>{};
      void addRate(String key, TextEditingController ctrl) {
        if (ctrl.text.trim().isNotEmpty) {
          rateCard[key] = double.tryParse(ctrl.text.trim()) ?? 0;
        }
      }
      addRate('per_post', _perPostCtrl);
      addRate('per_reel', _perReelCtrl);
      addRate('per_story', _perStoryCtrl);
      addRate('per_video', _perVideoCtrl);
      addRate('per_carousel', _perCarouselCtrl);
      addRate('per_live', _perLiveCtrl);
      addRate('per_youtube_integration', _perYtIntegrationCtrl);
      addRate('per_youtube_short', _perYtShortCtrl);
      rateCard['per_barter'] = _perBarter;
      if (_customPackages.isNotEmpty) rateCard['custom_packages'] = _customPackages;

      await widget.creatorRepo.updateCreatorProfile({
        'rate_card': rateCard,
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Edit Rate Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Set your prices for each deliverable type', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: _buildField('Per Post (\u20b9)', _perPostCtrl, 'e.g. 5000', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Per Reel (\u20b9)', _perReelCtrl, 'e.g. 8000', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('Per Story (\u20b9)', _perStoryCtrl, 'e.g. 2000', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Per Video (\u20b9)', _perVideoCtrl, 'e.g. 15000', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('Per Carousel (\u20b9)', _perCarouselCtrl, 'e.g. 6000', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('Per Live (\u20b9)', _perLiveCtrl, 'e.g. 10000', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('YT Integration (\u20b9)', _perYtIntegrationCtrl, 'e.g. 20000', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('YT Short (\u20b9)', _perYtShortCtrl, 'e.g. 8000', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 16),
                    // Barter toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.success),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Open to Barter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                          Switch(
                            value: _perBarter,
                            onChanged: (v) => setState(() => _perBarter = v),
                            activeThumbColor: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Custom packages
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Custom Packages', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _customPackages.add({'name': '', 'price': ''})),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                            child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(_customPackages.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: TextEditingController(text: _customPackages[i]['name'] ?? ''),
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  decoration: const InputDecoration(hintText: 'Package name', isDense: true, border: InputBorder.none),
                                  onChanged: (v) => _customPackages[i]['name'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(text: _customPackages[i]['price']?.toString() ?? ''),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  decoration: const InputDecoration(hintText: '\u20b9 Price', isDense: true, border: InputBorder.none),
                                  onChanged: (v) => _customPackages[i]['price'] = v,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _customPackages.removeAt(i)),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                      : const Text('Save Rate Card'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── Edit Past Work Sheet ─────────────────────────────────────────────────────

class _EditPastWorkSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditPastWorkSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditPastWorkSheet> createState() => _EditPastWorkSheetState();
}

class _EditPastWorkSheetState extends State<_EditPastWorkSheet> {
  late List<Map<String, dynamic>> _entries;
  final _pastBrandsCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entries = widget.profile.pastWork.map((e) => Map<String, dynamic>.from(e)).toList();
    _pastBrandsCtrl.text = widget.profile.pastBrands ?? '';
  }

  @override
  void dispose() {
    _pastBrandsCtrl.dispose();
    super.dispose();
  }

  void _addEntry() {
    setState(() {
      _entries.add({
        'brand_name': '',
        'deliverable_type': '',
        'platform': '',
        'date': '',
        'url': '',
        'description': '',
      });
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Filter out completely empty entries
      final cleaned = _entries.where((e) =>
        (e['brand_name'] ?? '').toString().isNotEmpty
      ).toList();

      await widget.creatorRepo.updateCreatorProfile({
        'past_work': cleaned,
        'past_brands': _pastBrandsCtrl.text.trim(),
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Past Work & Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Add your brand collaborations', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Legacy brands field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Past Brands (comma-separated)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _pastBrandsCtrl,
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: 'e.g. Nike, Myntra, boAt'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.work_history_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Structured Work Entries', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _addEntry,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                            child: const Text('+ Add Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_entries.length, (i) => _buildWorkEntry(i)),
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
                      : const Text('Save Past Work'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkEntry(int index) {
    final entry = _entries[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Entry ${index + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _entries.removeAt(index)),
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: entry['brand_name'] ?? ''),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Brand name', isDense: true),
            onChanged: (v) => entry['brand_name'] = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: (entry['deliverable_type'] ?? '').toString().isEmpty ? null : entry['deliverable_type'],
                      hint: const Text('Deliverable', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Post', child: Text('Post')),
                        DropdownMenuItem(value: 'Reel', child: Text('Reel')),
                        DropdownMenuItem(value: 'Story', child: Text('Story')),
                        DropdownMenuItem(value: 'Video', child: Text('Video')),
                        DropdownMenuItem(value: 'Carousel', child: Text('Carousel')),
                        DropdownMenuItem(value: 'Live', child: Text('Live')),
                        DropdownMenuItem(value: 'YT Integration', child: Text('YT Integration')),
                        DropdownMenuItem(value: 'YT Short', child: Text('YT Short')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => entry['deliverable_type'] = v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: (entry['platform'] ?? '').toString().isEmpty ? null : entry['platform'],
                      hint: const Text('Platform', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Instagram', child: Text('Instagram')),
                        DropdownMenuItem(value: 'YouTube', child: Text('YouTube')),
                        DropdownMenuItem(value: 'Twitter', child: Text('Twitter')),
                        DropdownMenuItem(value: 'LinkedIn', child: Text('LinkedIn')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => entry['platform'] = v),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: entry['date'] ?? ''),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Date (e.g. Jan 2025)', isDense: true),
            onChanged: (v) => entry['date'] = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: entry['url'] ?? ''),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'URL (optional)', isDense: true),
            keyboardType: TextInputType.url,
            onChanged: (v) => entry['url'] = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: entry['description'] ?? ''),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Description (optional)', isDense: true),
            maxLines: 2,
            onChanged: (v) => entry['description'] = v,
          ),
        ],
      ),
    );
  }
}

// ── Edit Collaboration Preferences Sheet ─────────────────────────────────────

class _EditCollaborationPrefsSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditCollaborationPrefsSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditCollaborationPrefsSheet> createState() => _EditCollaborationPrefsSheetState();
}

class _EditCollaborationPrefsSheetState extends State<_EditCollaborationPrefsSheet> {
  final _preferredCategoriesCtrl = TextEditingController();
  final _contentTypesCtrl = TextEditingController();
  final _brandSizeCtrl = TextEditingController();
  final _turnaroundCtrl = TextEditingController();
  bool _barterOpen = false;
  bool _exclusivityOpen = false;
  bool _willingToTravel = false;
  String _availabilityStatus = 'available';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.profile.collaborationPrefs ?? {};
    _preferredCategoriesCtrl.text = prefs['preferred_categories']?.toString() ?? '';
    _contentTypesCtrl.text = prefs['content_types']?.toString() ?? '';
    _brandSizeCtrl.text = prefs['brand_size']?.toString() ?? '';
    _barterOpen = prefs['barter_open'] == true;
    _exclusivityOpen = prefs['exclusivity_open'] == true;
    _willingToTravel = widget.profile.willingToTravel;
    _turnaroundCtrl.text = widget.profile.turnaroundDays > 0 ? widget.profile.turnaroundDays.toString() : '';
    _availabilityStatus = widget.profile.availabilityStatus;
  }

  @override
  void dispose() {
    _preferredCategoriesCtrl.dispose();
    _contentTypesCtrl.dispose();
    _brandSizeCtrl.dispose();
    _turnaroundCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final collabPrefs = <String, dynamic>{
        'preferred_categories': _preferredCategoriesCtrl.text.trim(),
        'content_types': _contentTypesCtrl.text.trim(),
        'brand_size': _brandSizeCtrl.text.trim(),
        'barter_open': _barterOpen,
        'exclusivity_open': _exclusivityOpen,
      };

      await widget.creatorRepo.updateCreatorProfile({
        'collaboration_prefs': collabPrefs,
        'willing_to_travel': _willingToTravel,
        'turnaround_days': int.tryParse(_turnaroundCtrl.text.trim()) ?? 0,
        'availability_status': _availabilityStatus,
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collaboration Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Tell brands what you are open to', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Preferred Categories', _preferredCategoriesCtrl, 'e.g. Fashion, Tech, Food (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Content Types', _contentTypesCtrl, 'e.g. Reels, Posts, Videos (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Brand Size Preference', _brandSizeCtrl, 'e.g. Startup, Mid-size, Enterprise (comma-separated)'),
                    const SizedBox(height: 16),
                    _buildField('Turnaround Days', _turnaroundCtrl, 'e.g. 7', keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    // Availability status dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Availability Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _availabilityStatus,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'available', child: Text('Available')),
                                DropdownMenuItem(value: 'busy', child: Text('Busy')),
                                DropdownMenuItem(value: 'not_accepting', child: Text('Not Accepting')),
                              ],
                              onChanged: (val) => setState(() => _availabilityStatus = val ?? 'available'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Toggles
                    _buildToggle('Open to Barter', Icons.swap_horiz_rounded, _barterOpen, (v) => setState(() => _barterOpen = v)),
                    const SizedBox(height: 10),
                    _buildToggle('Open to Exclusivity', Icons.star_rounded, _exclusivityOpen, (v) => setState(() => _exclusivityOpen = v)),
                    const SizedBox(height: 10),
                    _buildToggle('Willing to Travel', Icons.flight_rounded, _willingToTravel, (v) => setState(() => _willingToTravel = v)),
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
                      : const Text('Save Preferences'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? AppColors.success : AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ── Edit Audience Sheet ──────────────────────────────────────────────────────

class _EditAudienceSheet extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onSaved;
  final CreatorRepository creatorRepo;

  const _EditAudienceSheet({required this.profile, required this.onSaved, required this.creatorRepo});

  @override
  State<_EditAudienceSheet> createState() => _EditAudienceSheetState();
}

class _EditAudienceSheetState extends State<_EditAudienceSheet> {
  // Age split
  final _age1824Ctrl = TextEditingController();
  final _age2534Ctrl = TextEditingController();
  final _age3544Ctrl = TextEditingController();
  final _age45Ctrl = TextEditingController();
  // Gender split
  final _genderMaleCtrl = TextEditingController();
  final _genderFemaleCtrl = TextEditingController();
  final _genderOtherCtrl = TextEditingController();
  // Geo
  final _topCitiesCtrl = TextEditingController();
  final _topCountriesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final demo = widget.profile.audienceDemographics ?? {};
    final ageSplit = demo['age_split'] as Map<String, dynamic>? ?? {};
    _age1824Ctrl.text = _pctStr(ageSplit['18-24']);
    _age2534Ctrl.text = _pctStr(ageSplit['25-34']);
    _age3544Ctrl.text = _pctStr(ageSplit['35-44']);
    _age45Ctrl.text = _pctStr(ageSplit['45+']);
    final genderSplit = demo['gender_split'] as Map<String, dynamic>? ?? {};
    _genderMaleCtrl.text = _pctStr(genderSplit['male']);
    _genderFemaleCtrl.text = _pctStr(genderSplit['female']);
    _genderOtherCtrl.text = _pctStr(genderSplit['other']);
    _topCitiesCtrl.text = demo['top_cities']?.toString() ?? '';
    _topCountriesCtrl.text = demo['top_countries']?.toString() ?? '';
  }

  String _pctStr(dynamic val) {
    if (val == null || val == 0) return '';
    return val.toString();
  }

  @override
  void dispose() {
    for (final c in [_age1824Ctrl, _age2534Ctrl, _age3544Ctrl, _age45Ctrl,
        _genderMaleCtrl, _genderFemaleCtrl, _genderOtherCtrl,
        _topCitiesCtrl, _topCountriesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final demographics = <String, dynamic>{
        'age_split': {
          '18-24': double.tryParse(_age1824Ctrl.text.trim()) ?? 0,
          '25-34': double.tryParse(_age2534Ctrl.text.trim()) ?? 0,
          '35-44': double.tryParse(_age3544Ctrl.text.trim()) ?? 0,
          '45+': double.tryParse(_age45Ctrl.text.trim()) ?? 0,
        },
        'gender_split': {
          'male': double.tryParse(_genderMaleCtrl.text.trim()) ?? 0,
          'female': double.tryParse(_genderFemaleCtrl.text.trim()) ?? 0,
          'other': double.tryParse(_genderOtherCtrl.text.trim()) ?? 0,
        },
        'top_cities': _topCitiesCtrl.text.trim(),
        'top_countries': _topCountriesCtrl.text.trim(),
      };

      await widget.creatorRepo.updateCreatorProfile({
        'audience_demographics': demographics,
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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Audience Demographics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Help brands understand your audience', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Age Distribution (%)', Icons.cake_rounded),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('18-24', _age1824Ctrl, '%', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('25-34', _age2534Ctrl, '%', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('35-44', _age3544Ctrl, '%', keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildField('45+', _age45Ctrl, '%', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Gender Split (%)', Icons.people_rounded),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildField('Male %', _genderMaleCtrl, '%', keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildField('Female %', _genderFemaleCtrl, '%', keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildField('Other %', _genderOtherCtrl, '%', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Geography', Icons.public_rounded),
                    const SizedBox(height: 12),
                    _buildField('Top Cities', _topCitiesCtrl, 'e.g. Mumbai, Delhi, Bangalore (comma-separated)'),
                    const SizedBox(height: 12),
                    _buildField('Top Countries', _topCountriesCtrl, 'e.g. India, USA, UK (comma-separated)'),
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
                      : const Text('Save Demographics'),
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
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
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
      a: 'Go to Profile \u2192 Linked Accounts and tap on the platform you want to connect. You\'ll be redirected to authenticate with that platform.',
    ),
    (
      q: 'How do I apply for a campaign?',
      a: 'Browse campaigns in the Jobs tab. Open a campaign that interests you and tap "Apply Now". You\'ll need an active subscription to apply.',
    ),
    (
      q: 'When will I get paid for a completed campaign?',
      a: 'Payments are released by the brand after you submit proof of work and it gets approved. Funds are credited to your wallet within 2\u20133 business days.',
    ),
    (
      q: 'How do I upgrade to Pro?',
      a: 'Go to Jobs \u2192 tap any campaign \u2192 "Apply Now" will prompt you to subscribe. Choose a plan that suits you and complete the payment via Razorpay.',
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
                          color: isOpen ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
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
                color: iconColor.withValues(alpha: 0.1),
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
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
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
            'Made with \u2764\uFE0F in India',
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
