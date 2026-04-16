import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/campaign_repository.dart';
import '../../creator/data/creator_repository.dart';

class CreatorDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> creator;
  const CreatorDetailsScreen({super.key, required this.creator});

  @override
  ConsumerState<CreatorDetailsScreen> createState() => _CreatorDetailsScreenState();
}

class _CreatorDetailsScreenState extends ConsumerState<CreatorDetailsScreen> {
  Map<String, dynamic>? _analytics;
  bool _analyticsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final id = widget.creator['id']?.toString() ?? '';
    if (id.isEmpty) { setState(() => _analyticsLoading = false); return; }
    try {
      final data = await ref.read(creatorRepositoryProvider).getCreatorAnalytics(id);
      if (mounted) setState(() { _analytics = data; _analyticsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _analyticsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creator = widget.creator;
    final name = creator['name'] ?? 'Unknown Creator';
    final niche = (creator['niche']?.toString().trim().isNotEmpty == true)
        ? creator['niche'].toString() : 'Creator';
    final city = creator['city']?.toString() ?? '';
    final isVerified = creator['verified'] == true;
    final bio = creator['bio']?.toString() ?? '';
    final languages = creator['languages']?.toString() ?? '';
    final yearsExp = creator['years_experience'];
    final contentCats = creator['content_categories']?.toString() ?? '';
    final pastBrands = creator['past_brands']?.toString() ?? '';
    final rateCard = creator['rate_card'] as Map<String, dynamic>?;
    final socialLinks = creator['social_links'] as Map<String, dynamic>?;

    final instagramUsername = creator['instagram_username'];
    final instagramUrl = creator['instagram_url'];
    final instagramFollowers = creator['instagram_followers'] ?? 0;
    final instFollowers = instagramFollowers is int
        ? instagramFollowers : int.tryParse(instagramFollowers.toString()) ?? 0;

    final youtubeChannelTitle = creator['youtube_channel_title'];
    final youtubeUrl = creator['youtube_url'];
    final ytSubscribers = int.tryParse(creator['youtube_subscribers']?.toString() ?? '0') ?? 0;

    final instagramMediaCount = creator['cached_stats']?['instagram']?['media_count'];
    final youtubeVideoCount = creator['cached_stats']?['youtube']?['video_count'];

    String? avatarUrl = creator['avatar_url'];
    if (creator['cached_stats'] != null) {
      final cs = creator['cached_stats'];
      avatarUrl = cs['instagram']?['profile_picture'] ?? cs['youtube']?['thumbnail'] ?? avatarUrl;
    }

    final minBudget = creator['min_budget'] ?? 0;
    final hasBoth = instagramUsername != null && youtubeChannelTitle != null;
    final creatorId = creator['id']?.toString() ?? '';

    // New fields from backend
    final availabilityStatus = creator['availability_status']?.toString() ?? '';
    final responseTime = creator['response_time']?.toString() ?? '';
    final turnaroundDays = creator['turnaround_days'];
    final willingToTravel = creator['willing_to_travel'];
    final totalCampaigns = creator['total_campaigns'];
    final completedCampaigns = creator['completed_campaigns'];
    final avgRating = creator['avg_rating'];
    final audienceDemographics = creator['audience_demographics'] as Map<String, dynamic>?;
    final collaborationPrefs = creator['collaboration_prefs'] as Map<String, dynamic>?;
    final pastWork = creator['past_work'] as List<dynamic>?;

    final hasAvailabilityRow = availabilityStatus.isNotEmpty ||
        responseTime.isNotEmpty ||
        turnaroundDays != null ||
        willingToTravel != null;

    final hasPerformanceStats = totalCampaigns != null || completedCampaigns != null || avgRating != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            width: 92, height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.3),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(avatarUrl, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                                      )))
                                  : Center(child: Text(name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800))),
                            ),
                          ),
                          if (hasBoth)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                                ),
                                child: const Text('Multi', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(name,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF93C5FD)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(city.isNotEmpty ? '$niche • $city' : niche,
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      if (minBudget > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee_rounded, size: 13, color: Colors.white),
                              Text('From ${_formatBudget(minBudget)}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── 1. Availability & Performance Badge Row ─────────────
                  if (hasAvailabilityRow) ...[
                    _AvailabilityBadgeRow(
                      availabilityStatus: availabilityStatus,
                      responseTime: responseTime,
                      turnaroundDays: turnaroundDays,
                      willingToTravel: willingToTravel,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── 2. Performance Stats Row ────────────────────────────
                  if (hasPerformanceStats) ...[
                    _PerformanceStatsRow(
                      totalCampaigns: totalCampaigns,
                      completedCampaigns: completedCampaigns,
                      avgRating: avgRating,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Analytics Dashboard ──────────────────────────────────
                  _SectionHeader(label: 'Performance Analytics'),
                  const SizedBox(height: 12),
                  _AnalyticsDashboard(
                    analytics: _analytics,
                    loading: _analyticsLoading,
                    igFollowers: instFollowers,
                    ytSubscribers: ytSubscribers,
                  ),

                  // ── About / Bio ──────────────────────────────────────────
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'About'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(bio,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                    ),
                  ],

                  // ── 3. Audience Demographics Card ───────────────────────
                  if (audienceDemographics != null && audienceDemographics.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Audience Demographics'),
                    const SizedBox(height: 12),
                    _AudienceDemographicsCard(demographics: audienceDemographics),
                  ],

                  // ── Creator Details ──────────────────────────────────────
                  if (languages.isNotEmpty || (yearsExp != null && yearsExp != 0) || contentCats.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Creator Details'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (languages.isNotEmpty)
                            _DetailRow(
                              icon: Icons.language_rounded,
                              label: 'Languages',
                              child: Wrap(
                                spacing: 6, runSpacing: 4,
                                children: languages.split(',')
                                    .map((l) => l.trim())
                                    .where((l) => l.isNotEmpty)
                                    .map((l) => _Chip(label: l))
                                    .toList(),
                              ),
                            ),
                          if (yearsExp != null && yearsExp != 0) ...[
                            if (languages.isNotEmpty) const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.work_history_rounded,
                              label: 'Experience',
                              value: '$yearsExp ${yearsExp == 1 ? "year" : "years"}',
                            ),
                          ],
                          if (contentCats.isNotEmpty) ...[
                            if (languages.isNotEmpty || (yearsExp != null && yearsExp != 0))
                              const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.category_rounded,
                              label: 'Content',
                              child: Wrap(
                                spacing: 6, runSpacing: 4,
                                children: contentCats.split(',')
                                    .map((c) => c.trim())
                                    .where((c) => c.isNotEmpty)
                                    .map((c) => _Chip(label: c, color: AppColors.secondary))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // ── 4. Structured Past Work Section ─────────────────────
                  if (pastWork != null && pastWork.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Past Work'),
                    const SizedBox(height: 12),
                    _PastWorkSection(pastWork: pastWork),
                  ] else if (pastBrands.isNotEmpty) ...[
                    // Fall back to existing past_brands chips
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Past Collaborations'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Wrap(
                        spacing: 8, runSpacing: 8,
                        children: pastBrands.split(',')
                            .map((b) => b.trim())
                            .where((b) => b.isNotEmpty)
                            .map((b) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.business_rounded, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 5),
                                      Text(b, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],

                  // ── Rate Card ────────────────────────────────────────────
                  if (rateCard != null && rateCard.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Rate Card'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: rateCard.entries.map((e) {
                          final label = e.key.replaceAll('_', ' ').split(' ')
                              .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
                              .join(' ');
                          final amount = e.value?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.textHint),
                                  const SizedBox(width: 8),
                                  Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                ]),
                                Text('\u20B9$amount',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // ── 5. Collaboration Preferences Card ───────────────────
                  if (collaborationPrefs != null && collaborationPrefs.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Collaboration Preferences'),
                    const SizedBox(height: 12),
                    _CollaborationPrefsCard(prefs: collaborationPrefs),
                  ],

                  // ── Social Links ─────────────────────────────────────────
                  if (socialLinks != null && socialLinks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Connect'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: socialLinks.entries.map((e) {
                        IconData icon;
                        switch (e.key.toLowerCase()) {
                          case 'twitter': icon = Icons.tag_rounded; break;
                          case 'linkedin': icon = Icons.work_rounded; break;
                          default: icon = Icons.link_rounded;
                        }
                        final label = '${e.key[0].toUpperCase()}${e.key.substring(1)}';
                        return GestureDetector(
                          onTap: () async {
                            final uri = Uri.tryParse(e.value?.toString() ?? '');
                            if (uri != null && await canLaunchUrl(uri)) {
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(icon, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Social Platforms ─────────────────────────────────────
                  if (instagramUsername != null || youtubeChannelTitle != null) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(label: 'Social Platforms'),
                    const SizedBox(height: 12),
                    if (instagramUsername != null) ...[
                      _PlatformMediaCard(
                        gradient: AppColors.instagramGradient,
                        icon: Icons.camera_alt_rounded,
                        color: AppColors.instagram,
                        platform: 'Instagram',
                        handle: '@$instagramUsername',
                        primaryCount: instFollowers,
                        primaryLabel: 'Followers',
                        secondaryCount: instagramMediaCount,
                        secondaryLabel: 'Posts',
                        profileUrl: instagramUrl,
                        fetchMedia: () => ref.read(creatorRepositoryProvider)
                            .getCreatorMedia(creatorId, platform: 'instagram'),
                        mediaKey: 'instagram',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (youtubeChannelTitle != null)
                      _PlatformMediaCard(
                        gradient: AppColors.youtubeGradient,
                        icon: Icons.play_circle_rounded,
                        color: AppColors.youtube,
                        platform: 'YouTube',
                        handle: youtubeChannelTitle,
                        primaryCount: ytSubscribers,
                        primaryLabel: 'Subscribers',
                        secondaryCount: youtubeVideoCount,
                        secondaryLabel: 'Videos',
                        profileUrl: youtubeUrl,
                        fetchMedia: () => ref.read(creatorRepositoryProvider)
                            .getCreatorMedia(creatorId, platform: 'youtube'),
                        mediaKey: 'youtube',
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: ElevatedButton.icon(
            onPressed: () => _showInviteSheet(context, widget.creator),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: const Text('Invite to Campaign'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context, Map<String, dynamic> creator) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InviteToCampaignSheet(
        creatorId: creator['id'].toString(),
        creatorName: creator['name'] ?? 'this creator',
        campaignRepo: ref.read(campaignRepositoryProvider),
      ),
    );
  }

  String _formatBudget(dynamic budget) {
    final amount = budget is int ? budget : int.tryParse(budget.toString()) ?? 0;
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }
}

// ── 1. Availability & Performance Badge Row ─────────────────────────────────

class _AvailabilityBadgeRow extends StatelessWidget {
  final String availabilityStatus;
  final String responseTime;
  final dynamic turnaroundDays;
  final dynamic willingToTravel;

  const _AvailabilityBadgeRow({
    required this.availabilityStatus,
    required this.responseTime,
    this.turnaroundDays,
    this.willingToTravel,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (availabilityStatus.isNotEmpty)
          _availabilityBadge(availabilityStatus),
        if (responseTime.isNotEmpty)
          _infoBadge(
            icon: Icons.speed_rounded,
            label: 'Responds in $responseTime',
            color: const Color(0xFF0EA5E9),
          ),
        if (turnaroundDays != null)
          _infoBadge(
            icon: Icons.schedule_rounded,
            label: 'Delivers in $turnaroundDays ${_pluralDay(turnaroundDays)}',
            color: const Color(0xFF8B5CF6),
          ),
        if (willingToTravel == true)
          _infoBadge(
            icon: Icons.flight_rounded,
            label: 'Willing to travel',
            color: const Color(0xFFF59E0B),
          )
        else if (willingToTravel == false)
          _infoBadge(
            icon: Icons.home_rounded,
            label: 'Remote only',
            color: AppColors.textHint,
          ),
      ],
    );
  }

  String _pluralDay(dynamic days) {
    final n = days is int ? days : int.tryParse(days.toString()) ?? 0;
    return n == 1 ? 'day' : 'days';
  }

  Widget _availabilityBadge(String status) {
    Color color;
    IconData icon;
    String label;
    switch (status.toLowerCase()) {
      case 'available':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Available';
        break;
      case 'busy':
        color = AppColors.warning;
        icon = Icons.pause_circle_rounded;
        label = 'Busy';
        break;
      case 'not_accepting':
      case 'not accepting':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'Not Accepting';
        break;
      default:
        color = AppColors.textHint;
        icon = Icons.circle_rounded;
        label = status;
    }
    return _infoBadge(icon: icon, label: label, color: color);
  }

  Widget _infoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── 2. Performance Stats Row ────────────────────────────────────────────────

class _PerformanceStatsRow extends StatelessWidget {
  final dynamic totalCampaigns;
  final dynamic completedCampaigns;
  final dynamic avgRating;

  const _PerformanceStatsRow({
    this.totalCampaigns,
    this.completedCampaigns,
    this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    final total = _toInt(totalCampaigns);
    final completed = _toInt(completedCampaigns);
    final completionRate = total > 0 ? ((completed / total) * 100).round() : 0;
    final rating = _toDouble(avgRating);

    return Row(
      children: [
        if (total > 0)
          Expanded(child: _PerfStatTile(
            icon: Icons.campaign_rounded,
            value: total.toString(),
            label: 'Campaigns',
            color: AppColors.primary,
          )),
        if (total > 0 && completed > 0) const SizedBox(width: 8),
        if (completed > 0)
          Expanded(child: _PerfStatTile(
            icon: Icons.check_circle_rounded,
            value: completed.toString(),
            label: 'Completed',
            color: AppColors.success,
          )),
        if ((total > 0 || completed > 0) && total > 0) const SizedBox(width: 8),
        if (total > 0)
          Expanded(child: _PerfStatTile(
            icon: Icons.pie_chart_rounded,
            value: '$completionRate%',
            label: 'Completion',
            color: completionRate >= 80
                ? AppColors.success
                : completionRate >= 50
                    ? AppColors.warning
                    : AppColors.error,
          )),
        if ((total > 0 || completed > 0) && rating > 0) const SizedBox(width: 8),
        if (rating > 0)
          Expanded(child: _PerfStatTile(
            icon: Icons.star_rounded,
            value: rating.toStringAsFixed(1),
            label: 'Avg Rating',
            color: const Color(0xFFF59E0B),
          )),
      ],
    );
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _PerfStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _PerfStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── 3. Audience Demographics Card ───────────────────────────────────────────

class _AudienceDemographicsCard extends StatelessWidget {
  final Map<String, dynamic> demographics;
  const _AudienceDemographicsCard({required this.demographics});

  @override
  Widget build(BuildContext context) {
    final ageSplit = demographics['age_split'] as Map<String, dynamic>?;
    final genderSplit = demographics['gender_split'] as Map<String, dynamic>?;
    final topCities = demographics['top_cities'] as List<dynamic>?;
    final topCountries = demographics['top_countries'] as List<dynamic>?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Age Split ──
          if (ageSplit != null && ageSplit.isNotEmpty) ...[
            const _SectionLabel2(label: 'Age Distribution'),
            const SizedBox(height: 10),
            ...ageSplit.entries.map((e) {
              final pct = _toDouble(e.value);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: (pct / 100).clamp(0.0, 1.0),
                            child: Container(
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: AppColors.brandGradient,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Gender Split ──
          if (genderSplit != null && genderSplit.isNotEmpty) ...[
            if (ageSplit != null && ageSplit.isNotEmpty) const SizedBox(height: 16),
            const _SectionLabel2(label: 'Gender Distribution'),
            const SizedBox(height: 10),
            _GenderSplitBar(genderSplit: genderSplit),
          ],

          // ── Top Cities ──
          if (topCities != null && topCities.isNotEmpty) ...[
            if ((ageSplit != null && ageSplit.isNotEmpty) ||
                (genderSplit != null && genderSplit.isNotEmpty))
              const SizedBox(height: 16),
            const _SectionLabel2(label: 'Top Cities'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: topCities
                  .map((c) => _Chip(label: c.toString(), color: const Color(0xFF0EA5E9)))
                  .toList(),
            ),
          ],

          // ── Top Countries ──
          if (topCountries != null && topCountries.isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SectionLabel2(label: 'Top Countries'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: topCountries
                  .map((c) => _Chip(label: c.toString(), color: const Color(0xFF8B5CF6)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _GenderSplitBar extends StatelessWidget {
  final Map<String, dynamic> genderSplit;
  const _GenderSplitBar({required this.genderSplit});

  @override
  Widget build(BuildContext context) {
    final male = _toDouble(genderSplit['male'] ?? genderSplit['Male']);
    final female = _toDouble(genderSplit['female'] ?? genderSplit['Female']);
    final other = _toDouble(genderSplit['other'] ?? genderSplit['Other']);
    final total = male + female + other;
    if (total == 0) return const SizedBox.shrink();

    const maleColor = Color(0xFF3B82F6);
    const femaleColor = Color(0xFFEC4899);
    const otherColor = Color(0xFF8B5CF6);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 22,
            child: Row(
              children: [
                if (male > 0)
                  Expanded(
                    flex: (male * 10).round(),
                    child: Container(color: maleColor),
                  ),
                if (female > 0)
                  Expanded(
                    flex: (female * 10).round(),
                    child: Container(color: femaleColor),
                  ),
                if (other > 0)
                  Expanded(
                    flex: (other * 10).round(),
                    child: Container(color: otherColor),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (male > 0) _genderLabel('Male', '${male.toStringAsFixed(0)}%', maleColor),
            if (male > 0 && female > 0) const SizedBox(width: 16),
            if (female > 0) _genderLabel('Female', '${female.toStringAsFixed(0)}%', femaleColor),
            if ((male > 0 || female > 0) && other > 0) const SizedBox(width: 16),
            if (other > 0) _genderLabel('Other', '${other.toStringAsFixed(0)}%', otherColor),
          ],
        ),
      ],
    );
  }

  Widget _genderLabel(String label, String pct, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $pct',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ── 4. Past Work Section ────────────────────────────────────────────────────

class _PastWorkSection extends StatelessWidget {
  final List<dynamic> pastWork;
  const _PastWorkSection({required this.pastWork});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: pastWork.map((entry) {
        final work = entry as Map<String, dynamic>;
        final brandName = work['brand_name']?.toString() ?? '';
        final deliverableType = work['deliverable_type']?.toString() ?? '';
        final platform = work['platform']?.toString() ?? '';
        final date = work['date']?.toString() ?? '';
        final link = work['link']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brandName.isNotEmpty)
                        Text(
                          brandName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      if (deliverableType.isNotEmpty || platform.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          [deliverableType, platform].where((s) => s.isNotEmpty).join(' \u2022 '),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ],
                  ),
                ),
                if (link.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(link);
                      if (uri != null && await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 5. Collaboration Preferences Card ───────────────────────────────────────

class _CollaborationPrefsCard extends StatelessWidget {
  final Map<String, dynamic> prefs;
  const _CollaborationPrefsCard({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final preferredCategories = prefs['preferred_categories'] as List<dynamic>?;
    final contentTypes = prefs['content_types'] as List<dynamic>?;
    final barterOpen = prefs['barter_open'];
    final exclusivityOpen = prefs['exclusivity_open'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preferredCategories != null && preferredCategories.isNotEmpty) ...[
            const _SectionLabel2(label: 'Preferred Categories'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: preferredCategories
                  .map((c) => _Chip(label: c.toString(), color: AppColors.primary))
                  .toList(),
            ),
          ],
          if (contentTypes != null && contentTypes.isNotEmpty) ...[
            if (preferredCategories != null && preferredCategories.isNotEmpty)
              const SizedBox(height: 14),
            const _SectionLabel2(label: 'Content Types'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: contentTypes
                  .map((c) => _Chip(label: c.toString(), color: AppColors.secondary))
                  .toList(),
            ),
          ],
          if (barterOpen != null || exclusivityOpen != null) ...[
            if ((preferredCategories != null && preferredCategories.isNotEmpty) ||
                (contentTypes != null && contentTypes.isNotEmpty))
              const SizedBox(height: 14),
            Row(
              children: [
                if (barterOpen != null)
                  _collabIndicator(
                    icon: barterOpen == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    label: 'Barter',
                    enabled: barterOpen == true,
                  ),
                if (barterOpen != null && exclusivityOpen != null)
                  const SizedBox(width: 12),
                if (exclusivityOpen != null)
                  _collabIndicator(
                    icon: exclusivityOpen == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    label: 'Exclusivity',
                    enabled: exclusivityOpen == true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _collabIndicator({
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    final color = enabled ? AppColors.success : AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            enabled ? '$label Open' : '$label Closed',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Analytics Dashboard ───────────────────────────────────────────────────────

class _AnalyticsDashboard extends StatelessWidget {
  final Map<String, dynamic>? analytics;
  final bool loading;
  final int igFollowers;
  final int ytSubscribers;

  const _AnalyticsDashboard({
    this.analytics, required this.loading,
    required this.igFollowers, required this.ytSubscribers,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final igAnalytics = analytics?['instagram'] as Map<String, dynamic>?;
    final ytAnalytics = analytics?['youtube'] as Map<String, dynamic>?;

    if (igAnalytics == null && ytAnalytics == null) {
      return _buildBasicStats();
    }

    return Column(
      children: [
        if (igAnalytics != null)
          _PlatformAnalyticsCard(
            platform: 'Instagram',
            icon: Icons.camera_alt_rounded,
            gradient: AppColors.instagramGradient,
            color: AppColors.instagram,
            followers: igFollowers,
            analytics: igAnalytics,
            tier: igAnalytics['tier']?.toString() ?? '\u2014',
          ),
        if (igAnalytics != null && ytAnalytics != null) const SizedBox(height: 12),
        if (ytAnalytics != null)
          _PlatformAnalyticsCard(
            platform: 'YouTube',
            icon: Icons.play_circle_rounded,
            gradient: AppColors.youtubeGradient,
            color: AppColors.youtube,
            followers: ytSubscribers,
            followersLabel: 'Subscribers',
            analytics: ytAnalytics,
            tier: ytAnalytics['tier']?.toString() ?? '\u2014',
          ),
      ],
    );
  }

  Widget _buildBasicStats() {
    final hasIG = igFollowers > 0;
    final hasYT = ytSubscribers > 0;
    if (!hasIG && !hasYT) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.textHint, size: 20),
            SizedBox(width: 10),
            Text('No social platforms connected yet',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return Row(
      children: [
        if (hasIG)
          Expanded(child: _SimpleStatBox(
            label: 'IG Followers', value: _fmt(igFollowers),
            color: AppColors.instagram, icon: Icons.camera_alt_rounded,
          )),
        if (hasIG && hasYT) const SizedBox(width: 12),
        if (hasYT)
          Expanded(child: _SimpleStatBox(
            label: 'YT Subscribers', value: _fmt(ytSubscribers),
            color: AppColors.youtube, icon: Icons.play_circle_rounded,
          )),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _PlatformAnalyticsCard extends StatelessWidget {
  final String platform;
  final IconData icon;
  final LinearGradient gradient;
  final Color color;
  final int followers;
  final String followersLabel;
  final Map<String, dynamic> analytics;
  final String tier;

  const _PlatformAnalyticsCard({
    required this.platform, required this.icon, required this.gradient,
    required this.color, required this.followers, required this.analytics,
    required this.tier, this.followersLabel = 'Followers',
  });

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _fmt(dynamic v) {
    final n = _toInt(v);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n == 0) return '\u2014';
    return n.toString();
  }

  Color _engColor(String rate) {
    final r = double.tryParse(rate) ?? 0;
    if (r >= 5) return AppColors.success;
    if (r >= 2) return Colors.orange;
    return AppColors.textHint;
  }

  // Format seconds as "M:SS" or "H:MM:SS"
  String _fmtDuration(dynamic v) {
    final secs = _toInt(v);
    if (secs == 0) return '\u2014';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '$m:${s.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final engRate = analytics['engagement_rate']?.toString() ?? '0';
    final engColor = _engColor(engRate);
    final isInstagram = platform == 'Instagram';

    // Primary metrics
    final avgViews = analytics['avg_views'];
    final avgLikes = analytics['avg_likes'];
    final avgComments = analytics['avg_comments'];

    // Instagram-only
    final avgShares = analytics['avg_shares'];
    final avgSaves = analytics['avg_saves'];
    final avgReach = analytics['avg_reach'];
    final reach28d = analytics['reach_28d'];
    final impressions28d = analytics['impressions_28d'];
    final profileViews28d = analytics['profile_views_28d'];

    // YouTube-only
    final totalViews = analytics['total_views'];
    final videoCount = analytics['video_count'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.02)],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Text(platform, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                _TierBadge(tier: tier, color: color),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                // ── Hero row: Followers + Engagement ──
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: followersLabel,
                        value: _fmt(followers),
                        icon: Icons.people_rounded,
                        color: color,
                      ),
                    ),
                    Container(width: 1, height: 44, color: AppColors.divider),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Engagement',
                        value: engRate == '0' ? '\u2014' : '$engRate%',
                        icon: Icons.trending_up_rounded,
                        color: engColor,
                      ),
                    ),
                    if (!isInstagram) ...[
                      Container(width: 1, height: 44, color: AppColors.divider),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Total Views',
                          value: _fmt(totalViews),
                          icon: Icons.visibility_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // ── Per-post averages ──
                _SectionLabel2(label: isInstagram ? 'Per Post Averages' : 'Per Video Averages'),
                const SizedBox(height: 8),
                _MetricGrid(
                  metrics: [
                    _MetricItem(label: 'Avg Views', value: _fmt(avgViews), icon: Icons.play_arrow_rounded, color: color),
                    _MetricItem(label: 'Avg Likes', value: _fmt(avgLikes), icon: Icons.favorite_rounded, color: const Color(0xFFE91E63)),
                    _MetricItem(label: 'Avg Comments', value: _fmt(avgComments), icon: Icons.comment_rounded, color: const Color(0xFF0EA5E9)),
                    if (isInstagram) ...[
                      _MetricItem(label: 'Avg Shares', value: _fmt(avgShares), icon: Icons.share_rounded, color: const Color(0xFF8B5CF6)),
                      _MetricItem(label: 'Avg Saves', value: _fmt(avgSaves), icon: Icons.bookmark_rounded, color: const Color(0xFFF59E0B)),
                      _MetricItem(label: 'Avg Reach', value: _fmt(avgReach), icon: Icons.radar_rounded, color: AppColors.success),
                    ] else ...[
                      _MetricItem(label: 'Avg Duration', value: _fmtDuration(analytics['avg_duration']), icon: Icons.timer_rounded, color: const Color(0xFF8B5CF6)),
                      _MetricItem(label: 'Total Videos', value: _fmt(videoCount), icon: Icons.video_library_rounded, color: AppColors.youtube),
                      _MetricItem(label: 'Total Views', value: _fmt(analytics['total_views']), icon: Icons.visibility_rounded, color: const Color(0xFF6366F1)),
                    ],
                  ],
                ),

                // ── 28-day account insights (Instagram only) ──
                if (isInstagram && (reach28d != null || impressions28d != null || profileViews28d != null)) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  _SectionLabel2(label: 'Last 28 Days (Account)'),
                  const SizedBox(height: 8),
                  _MetricGrid(
                    metrics: [
                      if (reach28d != null)
                        _MetricItem(label: 'Reach', value: _fmt(reach28d), icon: Icons.wifi_tethering_rounded, color: AppColors.instagram),
                      if (impressions28d != null)
                        _MetricItem(label: 'Impressions', value: _fmt(impressions28d), icon: Icons.remove_red_eye_rounded, color: const Color(0xFF6366F1)),
                      if (profileViews28d != null)
                        _MetricItem(label: 'Profile Views', value: _fmt(profileViews28d), icon: Icons.person_search_rounded, color: const Color(0xFF0EA5E9)),
                    ],
                  ),
                ],

                // ── YouTube Analytics API: 28-day data ──
                if (!isInstagram) _YoutubeAnalytics28d(analytics: analytics, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── YouTube 28-day Analytics section ─────────────────────────────────────────

class _YoutubeAnalytics28d extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final Color color;
  const _YoutubeAnalytics28d({required this.analytics, required this.color});

  String _fmt(dynamic v) {
    if (v == null) return '\u2014';
    double n;
    if (v is double) n = v;
    else if (v is int) n = v.toDouble();
    else n = double.tryParse(v.toString()) ?? 0;
    if (n == 0) return '\u2014';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _fmtHours(dynamic v) {
    if (v == null) return '\u2014';
    final mins = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (mins == 0) return '\u2014';
    final hours = mins / 60;
    if (hours >= 1000) return '${(hours / 1000).toStringAsFixed(1)}Kh';
    return '${hours.toStringAsFixed(0)}h';
  }

  String _fmtDur(dynamic v) {
    if (v == null) return '\u2014';
    final secs = (v is double) ? v.toInt() : (v is int ? v : int.tryParse(v.toString()) ?? 0);
    if (secs == 0) return '\u2014';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _fmtPct(dynamic v) {
    if (v == null) return '\u2014';
    final pct = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (pct == 0) return '\u2014';
    return '${pct.toStringAsFixed(1)}%';
  }

  String _fmtCtr(dynamic v) {
    if (v == null) return '\u2014';
    final ctr = (v is double) ? v : double.tryParse(v.toString()) ?? 0.0;
    if (ctr == 0) return '\u2014';
    return '${(ctr * 100).toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final d = analytics['analytics_28d'] as Map<String, dynamic>?;
    final channelAge = analytics['channel_age_years'];
    final country = analytics['country'];
    final hasChannelMeta = channelAge != null || country != null;
    if (d == null && !hasChannelMeta) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d != null) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _SectionLabel2(label: 'Last 28 Days (YouTube Analytics)'),
          const SizedBox(height: 8),
          _MetricGrid(
            metrics: [
              _MetricItem(label: 'Watch Time', value: _fmtHours(d['estimatedMinutesWatched']), icon: Icons.access_time_rounded, color: AppColors.youtube),
              _MetricItem(label: 'Avg View Duration', value: _fmtDur(d['averageViewDuration']), icon: Icons.timer_outlined, color: const Color(0xFF8B5CF6)),
              _MetricItem(label: 'Avg % Viewed', value: _fmtPct(d['averageViewPercentage']), icon: Icons.data_usage_rounded, color: const Color(0xFF0EA5E9)),
              _MetricItem(label: 'Impressions', value: _fmt(d['impressions']), icon: Icons.remove_red_eye_rounded, color: const Color(0xFF6366F1)),
              _MetricItem(label: 'CTR', value: _fmtCtr(d['impressionClickThroughRate']), icon: Icons.ads_click_rounded, color: AppColors.success),
              _MetricItem(label: 'Shares', value: _fmt(d['shares']), icon: Icons.share_rounded, color: const Color(0xFFE91E63)),
              _MetricItem(label: 'Subs Gained', value: _fmt(d['subscribersGained']), icon: Icons.person_add_rounded, color: AppColors.success),
              _MetricItem(label: 'Subs Lost', value: _fmt(d['subscribersLost']), icon: Icons.person_remove_rounded, color: const Color(0xFFEF4444)),
              _MetricItem(label: 'Likes (28d)', value: _fmt(d['likes']), icon: Icons.thumb_up_rounded, color: const Color(0xFFF59E0B)),
            ],
          ),
        ],
        if (hasChannelMeta) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _SectionLabel2(label: 'Channel Info'),
          const SizedBox(height: 8),
          _MetricGrid(
            metrics: [
              if (channelAge != null)
                _MetricItem(
                  label: 'Channel Age',
                  value: '${channelAge}y',
                  icon: Icons.cake_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              if (country != null && country.toString().isNotEmpty)
                _MetricItem(
                  label: 'Country',
                  value: country.toString(),
                  icon: Icons.public_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HeroMetric({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _SectionLabel2 extends StatelessWidget {
  final String label;
  const _SectionLabel2({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint,
              letterSpacing: 0.5)),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricItem({required this.label, required this.value, required this.icon, required this.color});
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricItem> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((m) => _MetricTile(item: m)).toList(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricItem item;
  const _MetricTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 40 - 28 - 16) / 3; // 3 per row
    return SizedBox(
      width: w,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(height: 5),
            Text(item.value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: item.color)),
            const SizedBox(height: 2),
            Text(item.label,
                style: const TextStyle(fontSize: 9, color: AppColors.textHint),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


class _TierBadge extends StatelessWidget {
  final String tier;
  final Color color;
  const _TierBadge({required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(tier, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _SimpleStatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SimpleStatBox({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

// ── Shared detail widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;
  const _DetailRow({required this.icon, required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500))),
        Expanded(
          child: value != null
              ? Text(value!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))
              : child ?? const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

// ── Expandable platform card with media dropdown ─────────────────────────────

class _PlatformMediaCard extends StatefulWidget {
  final LinearGradient gradient;
  final IconData icon;
  final Color color;
  final String platform;
  final String handle;
  final int primaryCount;
  final String primaryLabel;
  final dynamic secondaryCount;
  final String secondaryLabel;
  final String? profileUrl;
  final Future<Map<String, dynamic>> Function() fetchMedia;
  final String mediaKey; // 'instagram' or 'youtube'

  const _PlatformMediaCard({
    required this.gradient,
    required this.icon,
    required this.color,
    required this.platform,
    required this.handle,
    required this.primaryCount,
    required this.primaryLabel,
    this.secondaryCount,
    required this.secondaryLabel,
    this.profileUrl,
    required this.fetchMedia,
    required this.mediaKey,
  });

  @override
  State<_PlatformMediaCard> createState() => _PlatformMediaCardState();
}

class _PlatformMediaCardState extends State<_PlatformMediaCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _loading = false;
  List<dynamic>? _media;
  String? _error;
  late final AnimationController _chevronController;
  late final Animation<double> _chevronAngle;

  @override
  void initState() {
    super.initState();
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _chevronAngle = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _chevronController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _chevronController.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_expanded) {
      _chevronController.reverse();
      setState(() => _expanded = false);
      return;
    }
    _chevronController.forward();
    setState(() {
      _expanded = true;
      if (_media == null && !_loading) _loading = true;
    });

    if (_media != null) return; // already fetched
    try {
      final result = await widget.fetchMedia();
      final items = result[widget.mediaKey];
      if (mounted) {
        setState(() {
          _media = items is List ? items : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? widget.color.withOpacity(0.3) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.platform,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.handle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatPill(
                        value: _formatNumber(widget.primaryCount),
                        label: widget.primaryLabel,
                        color: widget.color,
                      ),
                      if (widget.secondaryCount != null) ...[
                        const SizedBox(height: 4),
                        _StatPill(
                          value: widget.secondaryCount.toString(),
                          label: widget.secondaryLabel,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 10),
                  RotationTransition(
                    turns: _chevronAngle,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded media section ───────────────────────────────────
          if (_expanded) ...[
            Divider(
              height: 1,
              color: widget.color.withOpacity(0.15),
              indent: 16,
              endIndent: 16,
            ),
            const SizedBox(height: 12),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.color,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Could not load ${widget.platform} content',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              )
            else if (_media == null || _media!.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'No recent ${widget.platform} content found.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Recent ${widget.platform} Posts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.color,
                      ),
                    ),
                    const Spacer(),
                    if (widget.profileUrl != null)
                      GestureDetector(
                        onTap: () => _launchUrl(widget.profileUrl!),
                        child: Text(
                          'View profile \u2192',
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 198,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: _media!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _media![index] as Map<String, dynamic>;
                    return _MediaThumbnailCard(
                      item: item,
                      accentColor: widget.color,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── Individual media thumbnail card ─────────────────────────────────────────

class _MediaThumbnailCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentColor;

  const _MediaThumbnailCard({required this.item, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final title = (item['title']?.toString() ?? '').trim();
    final thumbnailUrl = item['thumbnail_url']?.toString();
    final permalink = item['permalink']?.toString();
    final mediaType = item['media_type']?.toString() ?? '';
    final viewCount = item['view_count'];
    final likeCount = item['like_count'];
    final isVideo = mediaType == 'VIDEO' || mediaType == 'YOUTUBE';

    return GestureDetector(
      onTap: permalink != null && permalink.isNotEmpty
          ? () async {
              final uri = Uri.parse(permalink);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  SizedBox(
                    width: 140,
                    height: 116,
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ThumbnailPlaceholder(
                              color: accentColor,
                              isVideo: isVideo,
                            ),
                          )
                        : _ThumbnailPlaceholder(
                            color: accentColor,
                            isVideo: isVideo,
                          ),
                  ),
                  // Video badge
                  if (isVideo)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'VIDEO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.isNotEmpty ? title : '\u2014',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        if (viewCount != null && viewCount != 0) ...[
                          Icon(Icons.visibility_rounded,
                              size: 10, color: accentColor),
                          const SizedBox(width: 3),
                          Text(
                            _formatCount(viewCount),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (likeCount != null && likeCount != 0) ...[
                          const Icon(Icons.favorite_rounded,
                              size: 10, color: AppColors.secondary),
                          const SizedBox(width: 3),
                          Text(
                            _formatCount(likeCount),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(dynamic count) {
    final n = count is int ? count : int.tryParse(count.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  final Color color;
  final bool isVideo;
  const _ThumbnailPlaceholder({required this.color, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.08),
      child: Center(
        child: Icon(
          isVideo ? Icons.play_circle_outline_rounded : Icons.image_rounded,
          color: color.withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatPill(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InviteToCampaignSheet extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final CampaignRepository campaignRepo;

  const _InviteToCampaignSheet({
    required this.creatorId,
    required this.creatorName,
    required this.campaignRepo,
  });

  @override
  State<_InviteToCampaignSheet> createState() => _InviteToCampaignSheetState();
}

class _InviteToCampaignSheetState extends State<_InviteToCampaignSheet> {
  List<dynamic>? _campaigns;
  bool _loading = true;
  String? _error;
  String? _sendingId; // campaign ID currently being invited
  final Set<String> _unavailableIds = {}; // campaigns already invited/applied

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final campaigns = await widget.campaignRepo.listInvitableCampaigns(widget.creatorId);
      if (mounted) setState(() { _campaigns = campaigns; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _invite(String campaignId, String campaignTitle) async {
    setState(() => _sendingId = campaignId);
    try {
      await widget.campaignRepo.inviteCreator(campaignId, widget.creatorId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.creatorName} invited to "$campaignTitle"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isConflict = msg.contains('409') ||
            msg.contains('already applied') ||
            msg.contains('already been invited');
        setState(() {
          _sendingId = null;
          if (isConflict) _unavailableIds.add(campaignId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isConflict
                ? 'Creator already applied or invited to "$campaignTitle"'
                : 'Failed to send invite: $e'),
            backgroundColor: isConflict ? Colors.orange : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Invite to Campaign',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a campaign to invite ${widget.creatorName}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load campaigns', style: const TextStyle(color: AppColors.textSecondary)),
            ))
          else if (_campaigns == null || _campaigns!.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No eligible campaigns.\nCreate a new campaign or this creator has already been invited/applied.', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
            ))
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _campaigns!.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final c = _campaigns![index] as Map<String, dynamic>;
                  final id = c['id']?.toString() ?? '';
                  final title = c['title']?.toString() ?? 'Untitled';
                  final budget = c['budget'];
                  final status = c['status']?.toString() ?? '';
                  final isSending = _sendingId == id;
                  final isUnavailable = _unavailableIds.contains(id);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: budget != null
                        ? Text('\u20B9$budget \u2022 $status', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                        : Text(status, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : isUnavailable
                            ? const Text('Already applied',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                            : TextButton(
                                onPressed: _sendingId != null ? null : () => _invite(id, title),
                                child: const Text('Invite'),
                              ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
