import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/user_profile_repository.dart';
import '../../../wallet/presentation/subscription_prompt.dart';

class JobCard extends ConsumerWidget {
  final Map<String, dynamic> job;
  
  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = job['title'] ?? 'Untitled Job';
    final brandName = job['brand_name'] ?? 'Unknown Brand';
    final budget = job['budget'] ?? 0;
    final description = job['description'] ?? '';
    final platform = job['platform'] ?? '';
    
    // Watch user profile for subscription status
    final profileAsync = ref.watch(userProfileProvider);
    final isSubscribed = profileAsync.value?.subscriptionStatus == 'ACTIVE';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              brandName,
                              style: const TextStyle(color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '₹${_formatBudget(budget)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (platform.isNotEmpty)
                  _Tag(
                    label: platform.toUpperCase(),
                    color: _getPlatformColor(platform).withOpacity(0.1),
                    textColor: _getPlatformColor(platform),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: (job['applied'] == true) 
                      ? null 
                      : () {
                          if (isSubscribed) {
                            context.push('/submit-proposal', extra: job);
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => SubscriptionPrompt(
                                role: 'Creator',
                                onSuccess: () {
                                  // In a real app, you might want to refresh profile here
                                  // ref.refresh(userProfileProvider);
                                },
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    disabledBackgroundColor: Colors.green.withOpacity(0.1),
                    disabledForegroundColor: Colors.green,
                  ),
                  child: Text((job['applied'] == true) ? 'Applied' : 'Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBudget(dynamic budget) {
    final amount = budget is int ? budget : int.tryParse(budget.toString()) ?? 0;
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Colors.purple;
      case 'youtube':
        return Colors.red;
      case 'twitter':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Tag({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
