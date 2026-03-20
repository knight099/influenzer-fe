import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/job_repository.dart';

class SubmitProposalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? job;

  const SubmitProposalScreen({super.key, this.job});

  @override
  ConsumerState<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends ConsumerState<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidController = TextEditingController();
  final _coverLetterController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bidController.dispose();
    _coverLetterController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final jobId = widget.job?['id']?.toString();
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Invalid campaign ID')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bidAmount = double.tryParse(_bidController.text.trim()) ?? 0.0;
      await ref.read(jobRepositoryProvider).apply(jobId, {
        'bid_amount': bidAmount,
        'cover_letter': _coverLetterController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job ?? {};
    final title = job['title'] ?? 'Untitled Campaign';
    final brandName = job['brand_name'] ?? 'Unknown Brand';
    final brandLogo = job['brand_logo']?.toString() ?? '';
    final budget = job['budget'] ?? 0;
    final platform = (job['platform'] ?? '').toString();
    final requirements = (job['requirements'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.textPrimary),
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Submit Proposal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campaign preview card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              gradient: brandLogo.isEmpty ? AppColors.subtleGradient : null,
                              color: brandLogo.isNotEmpty ? AppColors.border : null,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: brandLogo.isNotEmpty
                                  ? Image.network(brandLogo, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _BrandInitial(brandName))
                                  : _BrandInitial(brandName),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 12, color: AppColors.textHint),
                                    const SizedBox(width: 4),
                                    Text(
                                      brandName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹$budget',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Platform badge
                    if (platform.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _platformColor(platform).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_platformIcon(platform), size: 12, color: _platformColor(platform)),
                                const SizedBox(width: 5),
                                Text(
                                  platform.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _platformColor(platform),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Campaign brief summary (if available)
                    if (requirements.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Campaign Brief',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHint,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                        ),
                        child: Column(
                          children: [
                            if (requirements['content_type'] != null)
                              _BriefRow('Content type', requirements['content_type'].toString()),
                            if (requirements['key_message'] != null && requirements['key_message'].toString().isNotEmpty)
                              _BriefRow('Key message', requirements['key_message'].toString()),
                            if (requirements['hashtags'] != null && requirements['hashtags'].toString().isNotEmpty)
                              _BriefRow('Hashtags', requirements['hashtags'].toString()),
                            if (requirements['dos'] != null && requirements['dos'].toString().isNotEmpty)
                              _BriefRow("Do's", requirements['dos'].toString(), valueColor: AppColors.success),
                            if (requirements['donts'] != null && requirements['donts'].toString().isNotEmpty)
                              _BriefRow("Don'ts", requirements['donts'].toString(), valueColor: AppColors.error),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Bid price field
                    const Text(
                      'YOUR BID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
                            ),
                            child: const Center(
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _bidController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 18),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your bid amount';
                                if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                                if ((double.tryParse(v.trim()) ?? 0) <= 0) return 'Bid must be greater than 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Campaign budget: ₹$budget',
                      style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),

                    const SizedBox(height: 24),

                    // Cover letter field
                    const Text(
                      'COVER LETTER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHint,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextFormField(
                        controller: _coverLetterController,
                        maxLines: 6,
                        minLines: 5,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Tell the brand why you\'re the perfect fit — your niche, content style, audience, and what makes your proposal stand out.',
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 13,
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Write a cover letter';
                          if (v.trim().length < 20) return 'Cover letter is too short (min 20 chars)';
                          return null;
                        },
                      ),
                    ),

                    // Tips box
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Tips for a winning proposal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          _TipRow('Mention your audience size and demographics'),
                          _TipRow('Share links to similar past work'),
                          _TipRow('Explain how you\'ll meet the campaign goals'),
                          _TipRow('Keep it concise and professional'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Proposal'),
          ),
        ),
      ),
    );
  }

  Color _platformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return AppColors.instagram;
      case 'youtube':   return AppColors.youtube;
      default:          return AppColors.primary;
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return Icons.camera_alt_rounded;
      case 'youtube':   return Icons.play_circle_rounded;
      default:          return Icons.public_rounded;
    }
  }
}

class _BrandInitial extends StatelessWidget {
  final String name;
  const _BrandInitial(this.name);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _BriefRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BriefRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;
  const _TipRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 5, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
