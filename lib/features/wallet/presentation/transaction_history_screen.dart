import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payment_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../brand/data/brand_profile_repository.dart';
import '../../creator/data/user_profile_repository.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Determine Role and Fetch Balance
    // We try both providers. Only one should return data for the logged-in user.
    final brandProfileAsync = ref.watch(brandProfileProvider);
    final creatorProfileAsync = ref.watch(userProfileProvider);
    
    // Simple logic: check which one has data. 
    // In a real app with strict role mgmt, checking AuthController state would be better.
    
    double balance = 0.0;
    bool isLoadingProfile = false;

    if (brandProfileAsync.hasValue) {
      balance = brandProfileAsync.value!.walletBalance;
    } else if (creatorProfileAsync.hasValue) {
      balance = creatorProfileAsync.value!.walletBalance;
    } else if (brandProfileAsync.isLoading || creatorProfileAsync.isLoading) {
      isLoadingProfile = true;
    }

    // 2. Fetch Transactions
    final transactionsFuture = ref.watch(paymentRepositoryProvider).getTransactions();

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: AppColors.primary,
            child: Column(
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (isLoadingProfile)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Text(
                    '₹${NumberFormat('#,##0.00').format(balance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: transactionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final transactions = snapshot.data ?? [];
                
                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions yet'));
                }

                return ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final amount = (tx['amount'] ?? 0).toDouble();
                    final type = tx['type'] ?? 'unknown'; // 'credit' or 'debit'
                    final reference = tx['reference'] ?? '';
                    final dateStr = tx['created_at'];
                    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
                    
                    final isCredit = type == 'credit';
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? Colors.green[50] : Colors.red[50],
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(isCredit ? 'Payment Received' : 'Payment Sent'),
                      subtitle: Text(
                        '$reference • ${DateFormat('dd MMM, yyyy').format(date)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${isCredit ? '+' : '-'}₹${NumberFormat('#,##0.00').format(amount)}',
                        style: TextStyle(
                          color: isCredit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
