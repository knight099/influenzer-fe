import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final job = application['campaign'] ?? application['job'] ?? {};
    final title = job['title'] ?? 'Untitled Job';
    final status = application['status'] ?? 'PENDING';
    final bidAmount = application['bid_amount'] ?? 0;
    final coverLetter = application['cover_letter'] ?? 'No cover letter';
    final videoUrl = application['video_url'];

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 16),
            
            // Bid Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Your Bid:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      '₹$bidAmount',
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Video Section
            const Text(
              'Trial Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: videoUrl != null
                  ? const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                    ) // TODO: Implement video player
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, color: Colors.grey, size: 48),
                          SizedBox(height: 8),
                          Text('No video attached', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Cover Letter
            const Text(
              'Cover Letter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                coverLetter,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
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
      case 'ACCEPTED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'PENDING':
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
