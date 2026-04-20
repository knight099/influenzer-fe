import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/user_profile_repository.dart';
import '../../../wallet/presentation/subscription_prompt.dart';
import '../../../brand/presentation/brand_details_screen.dart';

class JobCard extends ConsumerWidget {
  final Map<String, dynamic> job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = job['title'] ?? 'Untitled Job';
    final brandName = job['brand_name'] ?? 'Unknown Brand';
    final brandLogo = job['brand_logo']?.toString() ?? '';
    final budget = job['budget'] ?? 0;
    final description = job['description'] ?? '';
    final platform = job['platform'] ?? '';
    final isApplied = job['applied'] == true;

    final profileAsync = ref.watch(userProfileProvider);
    final isSubscribed = profileAsync.value?.subscriptionStatus == 'ACTIVE';

    final platformColor = _getPlatformColor(platform);
    final platformIcon = _getPlatformIcon(platform);

    return GestureDetector(
      onTap: () => _showDetails(context, isSubscribed),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            // Subtle violet glow — the dark glass signature
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: brand icon + info + budget
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand avatar + name (tappable to view brand profile)
                  GestureDetector(
                    onTap: () {
                      final brandId = job['brand_id']?.toString();
                      if (brandId != null && brandId.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BrandDetailsScreen(
                              brandId: brandId,
                              brandName: brandName,
                              brandLogo: brandLogo.isNotEmpty ? brandLogo : null,
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            gradient: brandLogo.isEmpty ? AppColors.subtleGradient : null,
                            color: brandLogo.isNotEmpty ? AppColors.surfaceVariant : null,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: brandLogo.isNotEmpty
                                ? Image.network(
                                    brandLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: ShaderMask(
                                        shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                                        child: Text(
                                          brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
                                          style: const TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: ShaderMask(
                                      shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                                      child: Text(
                                        brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
                                        style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            final brandId = job['brand_id']?.toString();
                            if (brandId != null && brandId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BrandDetailsScreen(
                                    brandId: brandId,
                                    brandName: brandName,
                                    brandLogo: brandLogo.isNotEmpty ? brandLogo : null,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 13, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  brandName,
                                  style: const TextStyle(
                                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Budget badge — gradient pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      '₹${_formatBudget(budget)}',
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Description
              if (description.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.55,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 14),

              // Bottom row
              Row(
                children: [
                  if (platform.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: platformColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: platformColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(platformIcon, size: 13, color: platformColor),
                          const SizedBox(width: 5),
                          Text(
                            platform.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: platformColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      const Text(
                        'Tap for details',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'Applied',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        if (isSubscribed) {
                          context.push('/submit-proposal', extra: job);
                        } else {
                          showDialog(
                            context: context,
                            builder: (_) => SubscriptionPrompt(
                              role: 'Creator',
                              onSuccess: () {},
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, bool isSubscribed) {
    final title = job['title'] ?? 'Untitled Job';
    final brandName = job['brand_name'] ?? 'Unknown Brand';
    final brandLogo = job['brand_logo']?.toString() ?? '';
    final budget = job['budget'] ?? 0;
    final description = job['description'] ?? '';
    final platform = job['platform'] ?? '';
    final requirements = job['requirements'] as Map<String, dynamic>? ?? {};
    final isApplied = job['applied'] == true;

    final platformColor = _getPlatformColor(platform);
    final platformIcon = _getPlatformIcon(platform);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Brand + title header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            gradient: brandLogo.isEmpty ? AppColors.subtleGradient : null,
                            color: brandLogo.isNotEmpty ? AppColors.surfaceVariant : null,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: brandLogo.isNotEmpty
                                ? Image.network(brandLogo, fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Center(
                                      child: ShaderMask(
                                        shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                                        child: Text(brandName[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                                      ),
                                    ))
                                : Center(
                                    child: ShaderMask(
                                      shaderCallback: (b) => AppColors.brandGradient.createShader(b),
                                      child: Text(brandName.isNotEmpty ? brandName[0].toUpperCase() : 'B',
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.3)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.business_rounded, size: 13, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text(brandName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        _DetailPill(
                          icon: Icons.currency_rupee_rounded,
                          color: AppColors.success,
                          label: '₹${_formatBudget(budget)}',
                        ),
                        const SizedBox(width: 10),
                        if (platform.isNotEmpty)
                          _DetailPill(
                            icon: platformIcon,
                            color: platformColor,
                            label: platform.toUpperCase(),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    if (description.isNotEmpty) ...[
                      _SectionLabel('About this campaign'),
                      const SizedBox(height: 8),
                      Text(description,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.65)),
                      const SizedBox(height: 20),
                    ],

                    if (requirements.isNotEmpty) ...[
                      _SectionLabel('Campaign brief'),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 12),

                    if (!isApplied)
                      Builder(
                        builder: (ctx2) => GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx2);
                            if (isSubscribed) {
                              context.push('/submit-proposal', extra: job);
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => SubscriptionPrompt(role: 'Creator', onSuccess: () {}),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('Apply Now',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Already Applied',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.success)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBudget(dynamic budget) {
    final amount = budget is int ? budget : (budget is double ? budget.toInt() : int.tryParse(budget.toString()) ?? 0);
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toString();
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return AppColors.instagram;
      case 'youtube': return AppColors.youtube;
      case 'twitter': return const Color(0xFF1DA1F2);
      default: return AppColors.primary;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return Icons.camera_alt_rounded;
      case 'youtube': return Icons.play_circle_rounded;
      case 'twitter': return Icons.alternate_email_rounded;
      default: return Icons.public_rounded;
    }
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _DetailPill({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppColors.textHint, letterSpacing: 0.8,
      ));
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
