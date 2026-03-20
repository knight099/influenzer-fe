import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../creator/data/proposal_repository.dart';

class SubmissionDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> submission;

  const SubmissionDetailsScreen({super.key, required this.submission});

  @override
  ConsumerState<SubmissionDetailsScreen> createState() => _SubmissionDetailsScreenState();
}

class _SubmissionDetailsScreenState extends ConsumerState<SubmissionDetailsScreen> {
  bool _isProcessing = false;
  late String _submissionStatus;

  @override
  void initState() {
    super.initState();
    _submissionStatus = (widget.submission['status'] ?? 'APPLIED').toString().toUpperCase();
  }

  Future<void> _acceptSubmission() async {
    final proposalId = widget.submission['id'];
    if (proposalId == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(proposalRepositoryProvider).updateStatus(proposalId.toString(), 'APPROVED');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _submissionStatus = 'APPROVED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission accepted! You can now pay the creator from the campaign page.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _rejectSubmission() async {
    final proposalId = widget.submission['id'];
    if (proposalId == null) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(proposalRepositoryProvider).updateStatus(proposalId.toString(), 'REJECTED');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _submissionStatus = 'REJECTED';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission rejected.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine info from submission
    final submission = widget.submission;
    final creatorName = submission['creator_name'] ?? 'Unknown Creator';
    final creatorAvatar = submission['creator_avatar']?.toString();
    final submissionStatus = _submissionStatus;
    final proposalText = (submission['cover_note'] ?? submission['proposal_text'] ?? '') as String;
    final bidAmount = submission['bid_amount'] ?? 0;
    final createdAt = submission['created_at'] ?? '';

    final instagramUsername = submission['instagram_username']?.toString() ?? '';
    final instagramUrl = submission['instagram_url']?.toString() ?? '';
    final instagramFollowers = submission['instagram_followers'];
    final instagramMediaCount = submission['instagram_media_count'];
    final youtubeChannelTitle = submission['youtube_channel_title']?.toString() ?? '';
    final youtubeUrl = submission['youtube_url']?.toString() ?? '';
    final youtubeSubscribers = submission['youtube_subscribers'];
    final youtubeVideoCount = submission['youtube_video_count'];
    final hasSocialStats = instagramUsername.isNotEmpty || youtubeChannelTitle.isNotEmpty;

    final creatorId = submission['creator_id']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Details'),
        actions: [
          if (creatorId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              tooltip: 'Chat with creator',
              onPressed: () => context.push('/chat-room', extra: {
                'conversation_id': submission['id']?.toString(),
                'recipient_id': creatorId,
                'recipient_name': creatorName,
                'recipient_avatar': creatorAvatar ?? '',
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Creator Header
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
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: creatorAvatar != null && creatorAvatar.isNotEmpty
                        ? NetworkImage(creatorAvatar)
                        : null,
                    child: (creatorAvatar == null || creatorAvatar.isEmpty)
                        ? Text(
                            creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    creatorName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (hasSocialStats) ...[
                    const SizedBox(height: 16),
                    _SocialStatsSection(
                      instagramUsername: instagramUsername,
                      instagramUrl: instagramUrl,
                      instagramFollowers: instagramFollowers,
                      instagramMediaCount: instagramMediaCount,
                      youtubeChannelTitle: youtubeChannelTitle,
                      youtubeUrl: youtubeUrl,
                      youtubeSubscribers: youtubeSubscribers,
                      youtubeVideoCount: youtubeVideoCount,
                    ),
                  ],
                ],
              ),
            ),

            // Submission Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Submitted',
                    value: _formatDate(createdAt),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.monetization_on,
                    label: 'Bid Amount',
                    value: '₹$bidAmount',
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.info,
                    label: 'Status',
                    value: submissionStatus.toUpperCase(),
                    valueColor: _getStatusColor(submissionStatus),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Proposal Section
            if (proposalText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proposal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          proposalText,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: submissionStatus == 'APPLIED'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _showRejectDialog,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _showAcceptDialog,
                        icon: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPLIED':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'FUNDED':
        return Colors.blue;
      case 'PAID':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Submission'),
        content: Text('Accept this submission from ${widget.submission['creator_name'] ?? 'this creator'}? You can pay them from the campaign management page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acceptSubmission();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Submission'),
        content: const Text('Are you sure you want to reject this submission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _rejectSubmission();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _SocialStatsSection extends StatefulWidget {
  final String instagramUsername;
  final String instagramUrl;
  final dynamic instagramFollowers;
  final dynamic instagramMediaCount;
  final String youtubeChannelTitle;
  final String youtubeUrl;
  final dynamic youtubeSubscribers;
  final dynamic youtubeVideoCount;

  const _SocialStatsSection({
    required this.instagramUsername,
    required this.instagramUrl,
    required this.instagramFollowers,
    required this.instagramMediaCount,
    required this.youtubeChannelTitle,
    required this.youtubeUrl,
    required this.youtubeSubscribers,
    required this.youtubeVideoCount,
  });

  @override
  State<_SocialStatsSection> createState() => _SocialStatsSectionState();
}

class _SocialStatsSectionState extends State<_SocialStatsSection> {
  bool _expanded = false;

  String _fmt(dynamic val) {
    if (val == null) return '—';
    final n = val is num ? val.toInt() : int.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bar_chart_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Social Stats',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(width: 4),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          if (widget.instagramUsername.isNotEmpty)
            _PlatformRow(
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFE1306C),
              handle: '@${widget.instagramUsername}',
              primaryLabel: 'Followers',
              primaryValue: _fmt(widget.instagramFollowers),
              secondaryLabel: 'Posts',
              secondaryValue: _fmt(widget.instagramMediaCount),
              url: widget.instagramUrl,
              onTap: widget.instagramUrl.isNotEmpty ? () => _launch(widget.instagramUrl) : null,
            ),
          if (widget.instagramUsername.isNotEmpty && widget.youtubeChannelTitle.isNotEmpty)
            const SizedBox(height: 8),
          if (widget.youtubeChannelTitle.isNotEmpty)
            _PlatformRow(
              icon: Icons.play_circle_rounded,
              color: const Color(0xFFFF0000),
              handle: widget.youtubeChannelTitle,
              primaryLabel: 'Subscribers',
              primaryValue: _fmt(widget.youtubeSubscribers),
              secondaryLabel: 'Videos',
              secondaryValue: _fmt(widget.youtubeVideoCount),
              url: widget.youtubeUrl,
              onTap: widget.youtubeUrl.isNotEmpty ? () => _launch(widget.youtubeUrl) : null,
            ),
        ],
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String handle;
  final String primaryLabel;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final String url;
  final VoidCallback? onTap;

  const _PlatformRow({
    required this.icon,
    required this.color,
    required this.handle,
    required this.primaryLabel,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.url,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                handle,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$primaryValue $primaryLabel',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '· $secondaryValue $secondaryLabel',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.open_in_new_rounded, size: 13, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
