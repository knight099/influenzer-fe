import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../wallet/data/payment_repository.dart';

class SubmissionDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> submission;

  const SubmissionDetailsScreen({super.key, required this.submission});

  @override
  ConsumerState<SubmissionDetailsScreen> createState() => _SubmissionDetailsScreenState();
}

class _SubmissionDetailsScreenState extends ConsumerState<SubmissionDetailsScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;
  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
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
            content: Text('Payment Successful! Submission Funded.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close dialog or screen? Maybe close dialog first 
        // Actually this is called from callback, dialog might cover screen.
        // But we handle dialog closing in _acceptSubmission before opening razorpay?
        // No, flow is: Dialog -> Accept -> Payment -> Success.
        // We will pop the screen or refresh state.
        
        // For now, let's pop back to Previous Screen as "work is done"
        context.pop(); 
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}')),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Handle external wallet
  }

  Future<void> _acceptSubmission() async {
    final bidAmount = widget.submission['bid_amount'] ?? 0;
    final proposalId = widget.submission['id']; // Assuming ID is here
    
    if (proposalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid Proposal ID')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Create Order
      final orderData = await ref.read(paymentRepositoryProvider).createOrder(
        proposalId.toString(),
        (bidAmount * 100).toInt(), // Convert to paise/cents if needed, usually backend expects amount ?
        // User request: "amount": 25000. Assuming currency units.
        // Razorpay expects smallest currency unit (paise). 
        // If 'bidAmount' is 250, then we send 25000.
        'INR',
      );
      
      _currentOrderId = orderData['order_id'];
      
      // 2. Open Notification/Checkout
      var options = {
        'key': 'rzp_test_placeholder', // Replace with environment variable
        'amount': (bidAmount * 100).toInt(), 
        'name': 'Influenzer',
        'description': 'Funding Proposal #${proposalId.toString().substring(0, 4)}',
        'order_id': _currentOrderId, // Important
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

  @override
  Widget build(BuildContext context) {
    // Determine info from submission
    final submission = widget.submission;
    final creatorName = submission['creator_name'] ?? 'Unknown Creator';
    final creatorFollowers = submission['creator_followers'] ?? 0;
    final creatorId = submission['creator_id'];
    final submissionStatus = submission['status'] ?? 'PENDING';
    final proposalText = submission['proposal_text'] ?? '';
    final bidAmount = submission['bid_amount'] ?? 0;
    final createdAt = submission['created_at'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Details'),
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
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      creatorName.isNotEmpty ? creatorName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    creatorName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatNumber(creatorFollowers)} followers',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // View Profile Button
                  ElevatedButton.icon(
                    onPressed: creatorId != null
                        ? () {
                            // Navigation logic...
                          }
                        : null,
                    icon: const Icon(Icons.person),
                    label: const Text('View Full Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                  ),
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
      bottomNavigationBar: submissionStatus.toUpperCase() == 'PENDING'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showRejectDialog,
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
                        label: const Text('Accept & Fund'), // Updated text
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
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(int num) {
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    }
    return num.toString();
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
      builder: (context) => AlertDialog(
        title: const Text('Accept & Fund Submission'),
        content: Text('You are about to accept this submission and fund ₹${widget.submission['bid_amount']} into escrow. Proceed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _acceptSubmission();    // Start payment flow
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Submission'),
        content: const Text('Are you sure you want to reject this submission?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Call API to reject (not implemented in this turn)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Submission rejected'),
                  backgroundColor: Colors.red,
                ),
              );
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
