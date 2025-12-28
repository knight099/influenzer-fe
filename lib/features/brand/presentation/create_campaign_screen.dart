import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class CreateCampaignScreen extends StatelessWidget {
  const CreateCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Campaign')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Label('Campaign Title'),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g. Summer Product Launch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _Label('Description'),
            TextFormField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Describe what you need...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Budget (Fixed)'),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '\$',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Platform'),
                      DropdownButtonFormField<String>(
                        items: const [
                          DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                          DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                        ],
                        onChanged: (val) {},
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Label('Reference Material'),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file, size: 32, color: Colors.grey),
                    Text('Upload PDF or Images'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Submit campaign
                Navigator.pop(context);
              },
              child: const Text('Post Campaign'),
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
