import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/campaign_repository.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basics
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Step 2: Platform & Format
  String? _platform;
  String? _contentType;

  // Step 3: Budget & Brief
  final _budgetCtrl = TextEditingController();
  final _keyMessageCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _dosCtrl = TextEditingController();
  final _dontsCtrl = TextEditingController();

  static const _stepLabels = ['Basics', 'Platform', 'Budget', 'Review'];

  static const _contentTypes = {
    'instagram': ['Reel', 'Story', 'Post', 'Reel + Story'],
    'youtube': ['Dedicated Video', 'Integration', 'Short'],
    'both': ['Full Package', 'Reel + Video', 'Story + Short'],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _keyMessageCtrl.dispose();
    _hashtagsCtrl.dispose();
    _dosCtrl.dispose();
    _dontsCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (!_validateStep()) return;
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateStep() {
    String? error;
    switch (_currentStep) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) error = 'Please enter a campaign title';
        else if (_descCtrl.text.trim().isEmpty) error = 'Please describe your campaign';
        break;
      case 1:
        if (_platform == null) error = 'Please select a platform';
        else if (_contentType == null) error = 'Please select a content format';
        break;
      case 2:
        final b = double.tryParse(_budgetCtrl.text.trim());
        if (b == null || b <= 0) error = 'Please enter a valid budget';
        break;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red[700]),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final requirements = <String, dynamic>{
        if (_contentType != null) 'content_type': _contentType,
        if (_keyMessageCtrl.text.trim().isNotEmpty)
          'key_message': _keyMessageCtrl.text.trim(),
        if (_hashtagsCtrl.text.trim().isNotEmpty)
          'hashtags': _hashtagsCtrl.text
              .trim()
              .split(RegExp(r'\s+'))
              .where((h) => h.isNotEmpty)
              .toList(),
        if (_dosCtrl.text.trim().isNotEmpty) 'dos': _dosCtrl.text.trim(),
        if (_dontsCtrl.text.trim().isNotEmpty) 'donts': _dontsCtrl.text.trim(),
      };

      await ref.read(campaignRepositoryProvider).createCampaign({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'budget': double.parse(_budgetCtrl.text.trim()),
        'platform': _platform == 'both' ? 'instagram,youtube' : _platform,
        'requirements': requirements,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign launched successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close_rounded : Icons.arrow_back_rounded,
          ),
          onPressed: _back,
        ),
        title: const Text(
          'Campaign Builder',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDone || isActive
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _stepLabels[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < _stepLabels.length - 1) const SizedBox(width: 6),
                    ],
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Step pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _StepBasics(titleCtrl: _titleCtrl, descCtrl: _descCtrl),
                _StepPlatform(
                  platform: _platform,
                  contentType: _contentType,
                  contentTypes: _contentTypes,
                  onPlatformChanged: (p) =>
                      setState(() { _platform = p; _contentType = null; }),
                  onContentTypeChanged: (ct) =>
                      setState(() => _contentType = ct),
                ),
                _StepBudget(
                  budgetCtrl: _budgetCtrl,
                  keyMessageCtrl: _keyMessageCtrl,
                  hashtagsCtrl: _hashtagsCtrl,
                  dosCtrl: _dosCtrl,
                  dontsCtrl: _dontsCtrl,
                ),
                _StepReview(
                  title: _titleCtrl.text,
                  description: _descCtrl.text,
                  platform: _platform ?? '',
                  contentType: _contentType ?? '',
                  budget: _budgetCtrl.text,
                  keyMessage: _keyMessageCtrl.text,
                  hashtags: _hashtagsCtrl.text,
                  dos: _dosCtrl.text,
                  donts: _dontsCtrl.text,
                ),
              ],
            ),
          ),

          // Bottom navigation
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _back,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16,
                        ),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == 3 ? 'Launch Campaign' : 'Continue',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Basics ────────────────────────────────────────────────────────────

class _StepBasics extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;

  const _StepBasics({required this.titleCtrl, required this.descCtrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.edit_note_rounded,
            title: 'Campaign Basics',
            subtitle: 'Give your campaign a clear identity',
          ),
          const SizedBox(height: 28),
          _FieldLabel('Campaign Title'),
          TextField(
            controller: titleCtrl,
            decoration: _inputDeco('e.g. Summer Product Launch 2025'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _FieldLabel('Description'),
          TextField(
            controller: descCtrl,
            maxLines: 6,
            decoration: _inputDeco(
              'Describe your product, target audience, and campaign goals...',
            ),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'A clear title and description attract better creator proposals.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Platform & Content Format ────────────────────────────────────────

class _StepPlatform extends StatelessWidget {
  final String? platform;
  final String? contentType;
  final Map<String, List<String>> contentTypes;
  final ValueChanged<String> onPlatformChanged;
  final ValueChanged<String> onContentTypeChanged;

  const _StepPlatform({
    required this.platform,
    required this.contentType,
    required this.contentTypes,
    required this.onPlatformChanged,
    required this.onContentTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formats =
        platform != null ? (contentTypes[platform] ?? <String>[]) : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.campaign_rounded,
            title: 'Platform & Format',
            subtitle: 'Where and how you want to be seen',
          ),
          const SizedBox(height: 28),
          _FieldLabel('Platform'),
          const SizedBox(height: 12),
          Row(
            children: [
              _PlatformTile(
                label: 'Instagram',
                icon: Icons.camera_alt_rounded,
                color: AppColors.instagram,
                selected: platform == 'instagram',
                onTap: () => onPlatformChanged('instagram'),
              ),
              const SizedBox(width: 12),
              _PlatformTile(
                label: 'YouTube',
                icon: Icons.play_circle_fill_rounded,
                color: AppColors.youtube,
                selected: platform == 'youtube',
                onTap: () => onPlatformChanged('youtube'),
              ),
              const SizedBox(width: 12),
              _PlatformTile(
                label: 'Both',
                icon: Icons.layers_rounded,
                color: AppColors.primary,
                selected: platform == 'both',
                onTap: () => onPlatformChanged('both'),
              ),
            ],
          ),
          if (formats.isNotEmpty) ...[
            const SizedBox(height: 28),
            _FieldLabel('Content Format'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: formats.map((ct) {
                final isSelected = ct == contentType;
                return GestureDetector(
                  onTap: () => onContentTypeChanged(ct),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      ct,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? color : AppColors.textHint, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Budget & Brief ────────────────────────────────────────────────────

class _StepBudget extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final TextEditingController keyMessageCtrl;
  final TextEditingController hashtagsCtrl;
  final TextEditingController dosCtrl;
  final TextEditingController dontsCtrl;

  const _StepBudget({
    required this.budgetCtrl,
    required this.keyMessageCtrl,
    required this.hashtagsCtrl,
    required this.dosCtrl,
    required this.dontsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.attach_money_rounded,
            title: 'Budget & Brief',
            subtitle: 'Set your budget and creative guidelines',
          ),
          const SizedBox(height: 28),
          _FieldLabel('Total Budget (₹)'),
          TextField(
            controller: budgetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDeco('e.g. 25000'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Key Message  (Optional)'),
          TextField(
            controller: keyMessageCtrl,
            maxLines: 2,
            decoration: _inputDeco(
              'What should creators communicate about your brand?',
            ),
          ),
          const SizedBox(height: 20),
          _FieldLabel('Hashtags  (Optional)'),
          TextField(
            controller: hashtagsCtrl,
            decoration: _inputDeco('#brand #product #launch'),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Dos'),
                    TextField(
                      controller: dosCtrl,
                      maxLines: 4,
                      decoration: _inputDeco('What to include...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel("Don'ts"),
                    TextField(
                      controller: dontsCtrl,
                      maxLines: 4,
                      decoration: _inputDeco('What to avoid...'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Review & Launch ───────────────────────────────────────────────────

class _StepReview extends StatelessWidget {
  final String title;
  final String description;
  final String platform;
  final String contentType;
  final String budget;
  final String keyMessage;
  final String hashtags;
  final String dos;
  final String donts;

  const _StepReview({
    required this.title,
    required this.description,
    required this.platform,
    required this.contentType,
    required this.budget,
    required this.keyMessage,
    required this.hashtags,
    required this.dos,
    required this.donts,
  });

  String get _platformLabel {
    switch (platform) {
      case 'instagram': return 'Instagram';
      case 'youtube':   return 'YouTube';
      case 'both':      return 'Instagram + YouTube';
      default:          return platform;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            icon: Icons.rocket_launch_rounded,
            title: 'Ready to Launch',
            subtitle: 'Review your campaign before publishing',
          ),
          const SizedBox(height: 24),

          // Campaign preview card
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isEmpty ? 'Untitled Campaign' : title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _platformLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          'OPEN',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ReviewRow(
                        Icons.description_outlined,
                        'Description',
                        description.isEmpty ? '—' : description,
                      ),
                      const Divider(height: 24),
                      _ReviewRow(
                        Icons.movie_outlined,
                        'Format',
                        contentType.isEmpty ? '—' : contentType,
                      ),
                      const Divider(height: 24),
                      _ReviewRow(
                        Icons.currency_rupee_rounded,
                        'Budget',
                        budget.isEmpty ? '—' : '₹$budget',
                      ),
                      if (keyMessage.isNotEmpty) ...[
                        const Divider(height: 24),
                        _ReviewRow(
                          Icons.message_outlined,
                          'Key Message',
                          keyMessage,
                        ),
                      ],
                      if (hashtags.isNotEmpty) ...[
                        const Divider(height: 24),
                        _ReviewRow(Icons.tag_rounded, 'Hashtags', hashtags),
                      ],
                      if (dos.isNotEmpty) ...[
                        const Divider(height: 24),
                        _ReviewRow(Icons.check_circle_outline_rounded, "Do's", dos),
                      ],
                      if (donts.isNotEmpty) ...[
                        const Divider(height: 24),
                        _ReviewRow(Icons.cancel_outlined, "Don'ts", donts),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.notifications_active_outlined,
                    color: Colors.green, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All verified creators will be notified when your campaign goes live.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReviewRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
