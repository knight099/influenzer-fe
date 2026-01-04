import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/job_repository.dart';

class SubmitProposalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? job;
  
  const SubmitProposalScreen({super.key, this.job});

  @override
  ConsumerState<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends ConsumerState<SubmitProposalScreen> {
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isVideoSelected = false;
  
  final _bidController = TextEditingController();
  final _coverLetterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill bid with budget if available, otherwise empty
    if (widget.job != null && widget.job?['budget'] != null) {
      _bidController.text = widget.job!['budget'].toString();
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    final jobId = widget.job?['id']?.toString();
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid Job ID')),
      );
      return;
    }

    if (_bidController.text.isEmpty || _coverLetterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bidAmount = double.tryParse(_bidController.text) ?? 0.0;
      
      await ref.read(jobRepositoryProvider).apply(jobId, {
        'bid_amount': bidAmount,
        'cover_letter': _coverLetterController.text,
        // TODO: Add video URL once upload is implemented
        'video_url': null, 
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal Submitted Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting proposal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobTitle = widget.job?['title'] ?? 'Campaign Details';
    
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proposal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              jobTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Complete the form below to submit your proposal', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _Label('Your Bid Price'),
            TextFormField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Cover Letter'),
            TextFormField(
              controller: _coverLetterController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Why are you a good fit?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _Label('Trial Video (Optional for now)'),
            if (!_isVideoSelected)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isUploading = true;
                  });
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      _isUploading = false;
                      _isVideoSelected = true;
                    });
                  });
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.video_library, size: 40, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text('Tap to select and compress video'),
                          ],
                        ),
                ),
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _isVideoSelected = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitProposal,
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit Proposal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }
}
