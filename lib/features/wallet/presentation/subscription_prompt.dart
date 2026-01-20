import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../wallet/data/payment_repository.dart';
import '../../../core/theme/app_colors.dart';

class SubscriptionPrompt extends ConsumerStatefulWidget {
  final String role;
  final VoidCallback onSuccess;

  const SubscriptionPrompt({
    super.key,
    required this.role,
    required this.onSuccess,
  });

  @override
  ConsumerState<SubscriptionPrompt> createState() => _SubscriptionPromptState();
}

class _SubscriptionPromptState extends ConsumerState<SubscriptionPrompt> {
  bool _isLoading = false;
  Future<List<dynamic>>? _plansFuture;

  @override
  void initState() {
    super.initState();
    _plansFuture = ref.read(paymentRepositoryProvider).getSubscriptionPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder<List<dynamic>>(
          future: _plansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load plans',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _plansFuture = ref.read(paymentRepositoryProvider).getSubscriptionPlans();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final plans = snapshot.data ?? [];
            final roleLower = widget.role.toLowerCase();
            
            // Filter plans by target_role matching the current user's role
            // Also check plan name if target_role is empty (fallback for legacy data)
            final matchingPlans = plans.where((plan) {
              final targetRole = (plan['target_role'] ?? '').toString().toLowerCase();
              final planName = (plan['name'] ?? '').toString().toLowerCase();
              
              // First check explicit target_role
              if (targetRole.isNotEmpty) {
                return targetRole == roleLower;
              }
              
              // Fallback: check if plan name contains the role (e.g., "Brand Annual", "Creator Monthly")
              return planName.contains(roleLower);
            }).toList();
            
            Map<String, dynamic> selectedPlan;
            
            if (matchingPlans.isNotEmpty) {
              selectedPlan = matchingPlans.first;
            } else if (plans.isNotEmpty) {
              // Fallback to first plan if no role-specific plan found
              selectedPlan = plans.first;
            } else {
              // No plans available
              return SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No subscription plans available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            final planId = selectedPlan['id'];
            final amount = selectedPlan['amount'] ?? 0;
            final currency = selectedPlan['currency'] ?? 'INR';
            final name = selectedPlan['name'] ?? 'Premium Plan';
            final description = selectedPlan['description'] ?? 'Unlock all features';
            final duration = selectedPlan['duration'] ?? 30;
            final interval = duration >= 365 ? 'Year' : 'Month';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Upgrade to $name',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${currency == 'INR' ? '₹' : currency} $amount',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                       Text(
                        '/$interval',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleSubscribe(planId),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Subscribe Now'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Maybe Later'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(String planId) async {
    setState(() => _isLoading = true);

    try {
      // 1. Create subscription and get payment URL
      final subscriptionData = await ref.read(paymentRepositoryProvider).subscribe(planId);
      
      final shortUrl = subscriptionData['short_url'] as String?;
      
      if (shortUrl == null || shortUrl.isEmpty) {
        throw Exception('No payment URL received');
      }
      
      // 2. Open Razorpay hosted payment page
      final uri = Uri.parse(shortUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        
        // 3. Show instruction to user
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete payment in browser. Subscription will activate automatically.'),
              duration: Duration(seconds: 5),
            ),
          );
          
          // Call onSuccess - the profile will be refreshed when user returns
          widget.onSuccess();
        }
      } else {
        throw Exception('Could not open payment page');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
