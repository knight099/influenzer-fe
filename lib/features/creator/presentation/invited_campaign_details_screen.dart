import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class InvitedCampaignDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> campaign;

  const InvitedCampaignDetailsScreen({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    final title = campaign['title'] ?? 'Untitled Campaign';
    final description = campaign['description'] ?? '';
    final budget = campaign['budget'] ?? 0;
    final platform = (campaign['platform'] ?? '').toString();
    final status = (campaign['status'] ?? 'OPEN').toString().toUpperCase();
    final invitedAt = campaign['invited_at'] ?? '';
    final requirements = (campaign['requirements'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Invitation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.monetization_on_outlined,
                    label: 'Budget',
                    value: '₹$budget',
                    valueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  if (platform.isNotEmpty)
                    _InfoRow(
                      icon: _platformIcon(platform),
                      label: 'Platform',
                      value: platform.toUpperCase(),
                    ),
                  if (invitedAt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.mail_outline,
                      label: 'Invited on',
                      value: _formatDate(invitedAt),
                    ),
                  ],
                ],
              ),
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'About this Campaign',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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

            if (requirements.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Campaign Brief',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
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

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/submit-proposal', extra: campaign),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Submit Proposal'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      default:
        return Icons.public_outlined;
    }
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
                style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontWeight: FontWeight.w500)),
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
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'OPEN':
        color = Colors.green;
        break;
      case 'CLOSED':
        color = Colors.red;
        break;
      case 'COMPLETED':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
