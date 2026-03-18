import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/campaign_repository.dart';
import '../../creator/data/creator_repository.dart';

class CreatorDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> creator;

  const CreatorDetailsScreen({super.key, required this.creator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = creator['name'] ?? 'Unknown Creator';
    final niche = (creator['niche']?.toString().trim().isNotEmpty == true)
        ? creator['niche'].toString()
        : 'Creator';
    final city = creator['city']?.toString() ?? '';
    final isVerified = creator['verified'] == true;

    final instagramUsername = creator['instagram_username'];
    final instagramUrl = creator['instagram_url'];
    final instagramFollowers = creator['instagram_followers'] ?? 0;
    final instFollowers = instagramFollowers is int
        ? instagramFollowers
        : int.tryParse(instagramFollowers.toString()) ?? 0;

    final youtubeChannelTitle = creator['youtube_channel_title'];
    final youtubeUrl = creator['youtube_url'];
    final ytSubscribers =
        int.tryParse(creator['youtube_subscribers']?.toString() ?? '0') ?? 0;

    final instagramMediaCount =
        creator['cached_stats']?['instagram']?['media_count'];
    final youtubeVideoCount =
        creator['cached_stats']?['youtube']?['video_count'];

    String? avatarUrl = creator['avatar_url'];
    if (creator['cached_stats'] != null) {
      final cs = creator['cached_stats'];
      avatarUrl =
          cs['instagram']?['profile_picture'] ?? cs['youtube']?['thumbnail'] ?? avatarUrl;
    }

    final minBudget = creator['min_budget'] ?? 0;
    final hasBoth = instagramUsername != null && youtubeChannelTitle != null;
    final creatorId = creator['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 16),
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
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.3),
                              border: Border.all(color: Colors.white, width: 3),
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
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          if (hasBoth)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Multi',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded,
                                size: 18, color: Color(0xFF93C5FD)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        city.isNotEmpty ? '$niche • $city' : niche,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      if (minBudget > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee_rounded,
                                  size: 13, color: Colors.white),
                              Text(
                                'From ${_formatBudget(minBudget)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

          // Platform stats section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instagramUsername != null || youtubeChannelTitle != null) ...[
                    const Text(
                      'Social Platforms',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
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
                        fetchMedia: () => ref
                            .read(creatorRepositoryProvider)
                            .getCreatorMedia(creatorId, platform: 'instagram'),
                        mediaKey: 'instagram',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (youtubeChannelTitle != null) ...[
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
                        fetchMedia: () => ref
                            .read(creatorRepositoryProvider)
                            .getCreatorMedia(creatorId, platform: 'youtube'),
                        mediaKey: 'youtube',
                      ),
                    ],
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
            onPressed: () => _showInviteSheet(context, ref, creator),
            icon: const Icon(Icons.campaign_rounded, size: 18),
            label: const Text('Invite to Campaign'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> creator) {
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
    final amount =
        budget is int ? budget : int.tryParse(budget.toString()) ?? 0;
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
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
                          'View profile →',
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
                      title.isNotEmpty ? title : '—',
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
      final campaigns = await widget.campaignRepo.listMyCampaigns();
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
              child: Text('No active campaigns found.\nCreate a campaign first.', textAlign: TextAlign.center,
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
                        ? Text('₹$budget • $status', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
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
