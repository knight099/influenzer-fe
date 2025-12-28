import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  bool _isUploading = false;
  bool _isVideoSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proposal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Running Shoe Promo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text('Nike • \$250 Fixed Price', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            _Label('Your Bid Price'),
            TextFormField(
              initialValue: '250',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Cover Letter'),
            TextFormField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Why are you a good fit?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _Label('Trial Video'),
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
              onPressed: _isVideoSelected
                  ? () {
                      // TODO: Submit proposal logic
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Submit Proposal'),
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
