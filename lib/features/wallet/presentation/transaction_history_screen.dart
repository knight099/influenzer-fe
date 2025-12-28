import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: AppColors.primary,
            child: Column(
              children: const [
                Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8),
                Text(
                  '\$1,250.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: 5,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final isCredit = index % 2 == 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit ? Colors.green[50] : Colors.red[50],
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(isCredit ? 'Payment Received' : 'Escrow Deposit'),
                  subtitle: Text(
                    'Campaign #${100 + index} • 28 Dec, 2025',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${isCredit ? '+' : '-'}\$250.00',
                    style: TextStyle(
                      color: isCredit ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
