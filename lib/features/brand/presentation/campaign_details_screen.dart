import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../creator/data/proposal_repository.dart';
import '../data/campaign_repository.dart';
import '../../wallet/data/payment_repository.dart';

class CampaignDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> campaign;

  const CampaignDetailsScreen({super.key, required this.campaign});

  @override
  ConsumerState<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends ConsumerState<CampaignDetailsScreen> {
  late String _status;
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _currentOrderId;
  late Future<List<dynamic>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _status = (widget.campaign['status'] ?? 'OPEN').toString().toUpperCase();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadSubmissions();
  }

  void _loadSubmissions() {
    final campaignId = widget.campaign['id']?.toString() ?? '';
    _submissionsFuture = ref.read(proposalRepositoryProvider).getProposalsByCampaign(campaignId);
  }

  void _refreshSubmissions() {
    setState(() => _loadSubmissions());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      if (_currentOrderId == null) return;
      await ref.read(paymentRepositoryProvider).verifyPayment(
        _currentOrderId!,
        response.paymentId!,
        response.signature!,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Creator has been paid.'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshSubmissions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<void> _payCreator(Map<String, dynamic> submission) async {
    final bidAmount = submission['bid_amount'] ?? 0;
    final proposalId = submission['id']?.toString();

    if (proposalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid proposal ID')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final orderData = await ref.read(paymentRepositoryProvider).createOrder(
        proposalId,
        (bidAmount * 100).toInt(),
        'INR',
      );

      _currentOrderId = orderData['order_id'];

      final options = {
        'key': 'rzp_test_Rt3Gu0Ho8fT81o',
        'amount': (bidAmount * 100).toInt(),
        'name': 'Influenzer',
        'description': 'Payment for ${submission['creator_name'] ?? 'Creator'}',
        'order_id': _currentOrderId,
        'prefill': {'contact': '8888888888', 'email': 'brand@example.com'},
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: $e')),
        );
      }
    }
  }

  Future<void> _releasePayment(Map<String, dynamic> submission) async {
    final proposalId = submission['id']?.toString();
    final creatorName = submission['creator_name'] ?? 'Creator';
    if (proposalId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Payment'),
        content: Text('Transfer 90% of the bid amount to $creatorName after work completion?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await ref.read(paymentRepositoryProvider).releaseFunds(proposalId);
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment released to creator successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshSubmissions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Release failed: $e')),
        );
      }
    }
  }

  Future<void> _endCampaign() async {
    final campaignId = widget.campaign['id']?.toString();
    if (campaignId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Campaign'),
        content: const Text('Are you sure you want to end this campaign? No new submissions will be accepted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Campaign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(campaignRepositoryProvider).closeCampaign(campaignId);
      if (mounted) {
        setState(() => _status = 'CLOSED');
        Navigator.pop(context); // close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign ended successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end campaign: $e')),
        );
      }
    }
  }

  Future<void> _deleteCampaign() async {
    final campaignId = widget.campaign['id']?.toString();
    if (campaignId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Campaign'),
        content: const Text('Are you sure you want to permanently delete this campaign? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(campaignRepositoryProvider).deleteCampaign(campaignId);
      if (mounted) {
        Navigator.pop(context); // close bottom sheet
        context.pop(); // go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete campaign: $e')),
        );
      }
    }
  }

  void _showManageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManageCampaignSheet(
        campaignId: widget.campaign['id']?.toString() ?? '',
        isClosed: _status == 'CLOSED',
        onEndCampaign: _endCampaign,
        onDeleteCampaign: _deleteCampaign,
        onPayCreator: _payCreator,
        onReleasePayment: _releasePayment,
        isProcessing: _isProcessing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.campaign['title'] ?? 'Untitled Campaign';
    final description = widget.campaign['description'] ?? '';
    final budget = widget.campaign['budget'] ?? 0;
    final platform = (widget.campaign['platform'] ?? '').toString();
    final createdAt = widget.campaign['created_at'] ?? '';
    final requirements = (widget.campaign['requirements'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar + hero
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textPrimary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _StatusBadge(status: _status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoPill(
                              icon: Icons.monetization_on_rounded,
                              label: '₹$budget',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(
                              icon: _getPlatformIcon(platform),
                              label: platform.isEmpty ? 'Any' : platform.toUpperCase(),
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            _InfoPill(
                              icon: Icons.calendar_today_rounded,
                              label: _formatDate(createdAt),
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  FutureBuilder<List<dynamic>>(
                    future: _submissionsFuture,
                    builder: (context, snap) {
                      final subs = (snap.data ?? []).cast<Map<String, dynamic>>();
                      final total = subs.length;
                      final approved = subs.where((s) =>
                          (s['status'] ?? '').toString().toUpperCase() == 'APPROVED').length;
                      final pending = subs.where((s) =>
                          (s['status'] ?? '').toString().toUpperCase() == 'APPLIED').length;
                      return Row(
                        children: [
                          _StatCard(label: 'Total', value: '$total', color: AppColors.primary),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Pending', value: '$pending', color: Colors.orange),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Approved', value: '$approved', color: Colors.green),
                        ],
                      );
                    },
                  ),

                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Campaign Brief
                  if (requirements.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Campaign Brief',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (requirements['content_type'] != null)
                            _BriefRow(label: 'Content type', value: requirements['content_type'].toString()),
                          if (requirements['key_message'] != null && requirements['key_message'].toString().isNotEmpty)
                            _BriefRow(label: 'Key message', value: requirements['key_message'].toString()),
                          if (requirements['hashtags'] != null && requirements['hashtags'].toString().isNotEmpty)
                            _BriefRow(label: 'Hashtags', value: requirements['hashtags'].toString()),
                          if (requirements['dos'] != null && requirements['dos'].toString().isNotEmpty)
                            _BriefRow(label: "Do's", value: requirements['dos'].toString(), valueColor: AppColors.success),
                          if (requirements['donts'] != null && requirements['donts'].toString().isNotEmpty)
                            _BriefRow(label: "Don'ts", value: requirements['donts'].toString(), valueColor: AppColors.error),
                        ],
                      ),
                    ),
                  ],

                  // Submissions section header
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Submissions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _refreshSubmissions,
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 16, color: AppColors.textHint),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(fontSize: 13, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Submissions list
          FutureBuilder<List<dynamic>>(
            future: _submissionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: _SubmissionCardSkeleton(),
                      ),
                      childCount: 3,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                final is404 = snapshot.error.toString().contains('404');
                if (is404) {
                  return SliverToBoxAdapter(child: _EmptySubmissions());
                }
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEBEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 28),
                          ),
                          const SizedBox(height: 12),
                          const Text('Failed to load submissions',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text('${snapshot.error}',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _refreshSubmissions,
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final submissions = (snapshot.data ?? []).cast<Map<String, dynamic>>();
              if (submissions.isEmpty) {
                return SliverToBoxAdapter(child: _EmptySubmissions());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubmissionCard(
                        submission: submissions[index],
                        onTap: () => context.push('/submission-details', extra: submissions[index]),
                        onApprove: _canApprove(submissions[index])
                            ? () => _updateStatus(submissions[index], 'APPROVED')
                            : null,
                        onReject: _canReject(submissions[index])
                            ? () => _updateStatus(submissions[index], 'REJECTED')
                            : null,
                      ),
                    ),
                    childCount: submissions.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            onPressed: _showManageSheet,
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('Manage Campaign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _status == 'CLOSED' ? AppColors.textSecondary : AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  bool _canApprove(Map<String, dynamic> sub) {
    final s = (sub['status'] ?? '').toString().toUpperCase();
    return s == 'APPLIED';
  }

  bool _canReject(Map<String, dynamic> sub) {
    final s = (sub['status'] ?? '').toString().toUpperCase();
    return s == 'APPLIED' || s == 'APPROVED';
  }

  Future<void> _updateStatus(Map<String, dynamic> sub, String newStatus) async {
    final id = sub['id']?.toString();
    if (id == null) return;
    try {
      await ref.read(proposalRepositoryProvider).updateStatus(id, newStatus);
      _refreshSubmissions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return Icons.camera_alt_rounded;
      case 'youtube': return Icons.play_circle_rounded;
      default: return Icons.public_rounded;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ─── Manage Campaign Sheet ────────────────────────────────────────────────────

class _ManageCampaignSheet extends ConsumerStatefulWidget {
  final String campaignId;
  final bool isClosed;
  final Future<void> Function() onEndCampaign;
  final Future<void> Function() onDeleteCampaign;
  final Future<void> Function(Map<String, dynamic>) onPayCreator;
  final Future<void> Function(Map<String, dynamic>) onReleasePayment;
  final bool isProcessing;

  const _ManageCampaignSheet({
    required this.campaignId,
    required this.isClosed,
    required this.onEndCampaign,
    required this.onDeleteCampaign,
    required this.onPayCreator,
    required this.onReleasePayment,
    required this.isProcessing,
  });

  @override
  ConsumerState<_ManageCampaignSheet> createState() => _ManageCampaignSheetState();
}

class _ManageCampaignSheetState extends ConsumerState<_ManageCampaignSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle + header
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    const Text(
                      'Manage Campaign',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _StatusBadge(status: widget.isClosed ? 'CLOSED' : 'OPEN'),
                  ],
                ),
              ),
              Container(height: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // End Campaign (only when OPEN)
                    if (!widget.isClosed) ...[
                      _SheetActionTile(
                        icon: Icons.stop_circle_outlined,
                        iconColor: Colors.orange,
                        title: 'End Campaign',
                        subtitle: 'Close this campaign to new submissions',
                        onTap: widget.onEndCampaign,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Delete Campaign (only when CLOSED)
                    if (widget.isClosed) ...[
                      _SheetActionTile(
                        icon: Icons.delete_outline_rounded,
                        iconColor: Colors.red,
                        title: 'Delete Campaign',
                        subtitle: 'Permanently remove this campaign',
                        titleColor: Colors.red,
                        onTap: widget.onDeleteCampaign,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Pay Creator section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pay Approved Creator',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select an approved creator to send payment',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<dynamic>>(
                            future: ref
                                .read(proposalRepositoryProvider)
                                .getProposalsByCampaign(widget.campaignId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }

                              final actionable = (snapshot.data ?? [])
                                  .cast<Map<String, dynamic>>()
                                  .where((s) {
                                    final st = (s['status'] ?? '').toString().toUpperCase();
                                    return st == 'APPROVED' || st == 'FUNDED' ||
                                           st == 'COMPLETED' || st == 'PAID';
                                  })
                                  .toList();

                              if (actionable.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.border,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.person_off_outlined,
                                            size: 18, color: AppColors.textHint),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'No approved submissions yet',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: actionable.map((sub) {
                                  final name = sub['creator_name'] ?? 'Creator';
                                  final avatar = sub['creator_avatar']?.toString();
                                  final bid = sub['bid_amount'] ?? 0;
                                  final status = (sub['status'] ?? '').toString().toUpperCase();
                                  final isPaid = status == 'PAID';
                                  final isFunded = status == 'FUNDED';
                                  final isCompleted = status == 'COMPLETED';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isFunded || isCompleted
                                            ? AppColors.primary.withValues(alpha: 0.3)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: AppColors.border,
                                          backgroundImage: (avatar != null && avatar.isNotEmpty)
                                              ? NetworkImage(avatar)
                                              : null,
                                          child: (avatar == null || avatar.isEmpty)
                                              ? Text(
                                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: AppColors.textPrimary,
                                                  )),
                                              Text('₹$bid · $status',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                  )),
                                            ],
                                          ),
                                        ),
                                        if (isPaid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.teal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
                                            ),
                                            child: const Text('PAID',
                                                style: TextStyle(
                                                  color: Colors.teal,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                )),
                                          )
                                        else if (isFunded || isCompleted)
                                          widget.isProcessing
                                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                              : ElevatedButton(
                                                  onPressed: () => widget.onReleasePayment(sub),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                                  ),
                                                  child: const Text('Release'),
                                                )
                                        else
                                          widget.isProcessing
                                              ? const SizedBox(
                                                  width: 20, height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : ElevatedButton(
                                                  onPressed: () => widget.onPayCreator(sub),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8)),
                                                    textStyle: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  child: const Text('Pay'),
                                                ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SheetActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SheetActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'OPEN':   color = Colors.green; break;
      case 'CLOSED': color = Colors.red; break;
      case 'COMPLETED': color = Colors.blue; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BriefRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 13,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final Map<String, dynamic> submission;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _SubmissionCard({
    required this.submission,
    required this.onTap,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final creatorName = submission['creator_name'] ?? 'Unknown Creator';
    final creatorAvatar = submission['creator_avatar']?.toString();
    final status = (submission['status'] ?? 'PENDING').toString().toUpperCase();
    final createdAt = submission['created_at'] ?? '';
    final bidAmount = submission['bid_amount'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.border,
                  backgroundImage: (creatorAvatar != null && creatorAvatar.isNotEmpty)
                      ? NetworkImage(creatorAvatar)
                      : null,
                  child: (creatorAvatar == null || creatorAvatar.isEmpty)
                      ? Text(
                          creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creatorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        createdAt.isNotEmpty ? _formatDate(createdAt) : '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusChip(status: status),
                    if (bidAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹$bidAmount',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            // Quick action buttons for APPLIED status
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  if (onApprove != null && onReject != null) const SizedBox(width: 8),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _EmptySubmissions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.subtleGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text(
              'No submissions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Creators who apply to this campaign\nwill appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionCardSkeleton extends StatelessWidget {
  const _SubmissionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 140, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 11, width: 80, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          Container(height: 22, width: 60, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'APPLIED':   color = Colors.orange; break;
      case 'APPROVED':  color = Colors.green; break;
      case 'REJECTED':  color = Colors.red; break;
      case 'FUNDED':    color = Colors.blue; break;
      case 'PAID':
      case 'COMPLETED': color = Colors.teal; break;
      default:          color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
