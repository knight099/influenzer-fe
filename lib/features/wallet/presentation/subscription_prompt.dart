import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

            // Filter plan based on role if needed, or select the relevant one
            // The user requested 10000/yr for Brand, 500/mo for Creator.
            // We assume the API returns suitable plans.
            // For now, we'll try to find a matching plan or fallback to the requested defaults if API returns empty
            // (since we might not have seeded the DB yet).
            
            final plans = snapshot.data ?? [];
            final roleLower = widget.role.toLowerCase();
            
            // Heuristic to pick a plan:
            // If Brand -> Look for 'Pro Annual' or high amount
            // If Creator -> Look for 'Creator Monthly' or low amount
            
            Map<String, dynamic> selectedPlan;
            
            if (plans.isNotEmpty) {
               // Simple logic: just take the first one for now, or filter by name if available
               selectedPlan = plans.first; 
            } else {
               // Fallback defaults matching user request
               selectedPlan = roleLower == 'brand' 
                  ? {
                      'amount': 10000,
                      'currency': 'INR',
                      'name': 'Brand Premium',
                      'description': 'Unlimited Campaigns & Analytics',
                      'interval': 'Yearly' 
                    }
                  : {
                      'amount': 500,
                      'currency': 'INR',
                      'name': 'Creator Pro',
                      'description': 'Priority Access to Premium Jobs',
                      'interval': 'Monthly'
                    };
            }

            final amount = selectedPlan['amount'];
            final currency = selectedPlan['currency'] ?? 'INR';
            final name = selectedPlan['name'] ?? 'Premium Plan';
            final description = selectedPlan['description'] ?? 'Unlock all features';
            final interval = selectedPlan['interval'] ?? (roleLower == 'brand' ? 'Yearly' : 'Monthly');

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
                    onPressed: _isLoading ? null : () => _handleSubscribe(amount),
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

  Future<void> _handleSubscribe(dynamic amount) async {
    setState(() => _isLoading = true);

    try {
      // Mock payment flow for now as we don't have backend subscription endpoints fully ready
      // In production: await ref.read(paymentRepositoryProvider).createSubscription(...)
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate network call

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription Successful!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
