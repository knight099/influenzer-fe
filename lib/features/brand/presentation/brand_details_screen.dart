import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../data/brand_profile_repository.dart';

class BrandDetailsScreen extends ConsumerStatefulWidget {
  final String brandId;
  final String? brandName;
  final String? brandLogo;

  const BrandDetailsScreen({
    super.key,
    required this.brandId,
    this.brandName,
    this.brandLogo,
  });

  @override
  ConsumerState<BrandDetailsScreen> createState() => _BrandDetailsScreenState();
}

class _BrandDetailsScreenState extends ConsumerState<BrandDetailsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(brandProfileRepositoryProvider).getBrandProfile(widget.brandId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _data?['company_name'] ?? widget.brandName ?? 'Brand';
    final logoUrl = _data?['logo_url'] ?? widget.brandLogo;
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'B';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.brandGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -20,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20, left: -30,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(17),
                                child: logoUrl != null && logoUrl.toString().isNotEmpty
                                    ? Image.network(
                                        logoUrl.toString(),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                                        ),
                                      )
                                    : Center(
                                        child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              companyName,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                            ),
                            if (_data?['industry'] != null && _data!['industry'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _data!['industry'].toString(),
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    const Text('Failed to load brand', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                ..._buildContent(),
                const SizedBox(height: 80),
              ]),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    final data = _data!;
    final widgets = <Widget>[];

    // Description / About
    final desc = data['description']?.toString() ?? '';
    if (desc.isNotEmpty) {
      widgets.addAll([
        _sectionLabel('About'),
        _card([
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.65)),
          ),
        ]),
        const SizedBox(height: 20),
      ]);
    }

    // Company details
    final industry = data['industry']?.toString() ?? '';
    final foundedYear = data['founded_year'];
    final companySize = data['company_size']?.toString() ?? '';
    final headquarters = data['headquarters']?.toString() ?? '';
    final hasDetails = industry.isNotEmpty || (foundedYear != null && foundedYear != 0) || companySize.isNotEmpty || headquarters.isNotEmpty;

    if (hasDetails) {
      final rows = <Widget>[];
      if (industry.isNotEmpty) rows.add(_detailRow(Icons.category_rounded, const Color(0xFF6366F1), 'Industry', industry, rows.isNotEmpty));
      if (foundedYear != null && foundedYear != 0) rows.add(_detailRow(Icons.calendar_month_rounded, AppColors.warning, 'Founded', foundedYear.toString(), rows.isNotEmpty));
      if (companySize.isNotEmpty) rows.add(_detailRow(Icons.people_rounded, AppColors.success, 'Company Size', companySize, rows.isNotEmpty));
      if (headquarters.isNotEmpty) rows.add(_detailRow(Icons.location_on_rounded, AppColors.error, 'Headquarters', headquarters, rows.isNotEmpty));

      widgets.addAll([
        _sectionLabel('Company Details'),
        _card(rows),
        const SizedBox(height: 20),
      ]);
    }

    // Campaign focus
    final productCats = data['product_categories']?.toString() ?? '';
    final targetAudience = data['target_audience']?.toString() ?? '';
    final campaignTypes = data['campaign_types']?.toString() ?? '';
    final hasCampaign = productCats.isNotEmpty || targetAudience.isNotEmpty || campaignTypes.isNotEmpty;

    if (hasCampaign) {
      final rows = <Widget>[];
      if (productCats.isNotEmpty) rows.add(_tagRow(Icons.shopping_bag_rounded, AppColors.primary, 'Product Categories', productCats, rows.isNotEmpty));
      if (targetAudience.isNotEmpty) rows.add(_detailRow(Icons.groups_rounded, const Color(0xFF0EA5E9), 'Target Audience', targetAudience, rows.isNotEmpty));
      if (campaignTypes.isNotEmpty) rows.add(_tagRow(Icons.campaign_rounded, AppColors.warning, 'Campaign Types', campaignTypes, rows.isNotEmpty));

      widgets.addAll([
        _sectionLabel('Campaign Focus'),
        _card(rows),
        const SizedBox(height: 20),
      ]);
    }

    // Social links & website
    final instagramUrl = data['instagram_url']?.toString() ?? '';
    final twitterUrl = data['twitter_url']?.toString() ?? '';
    final linkedinUrl = data['linkedin_url']?.toString() ?? '';
    final website = data['website']?.toString() ?? '';
    final hasSocial = instagramUrl.isNotEmpty || twitterUrl.isNotEmpty || linkedinUrl.isNotEmpty || website.isNotEmpty;

    if (hasSocial) {
      widgets.addAll([
        _sectionLabel('Links'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (website.isNotEmpty)
                  _linkRow(Icons.language_rounded, const Color(0xFF6366F1), 'Website', website, instagramUrl.isNotEmpty || twitterUrl.isNotEmpty || linkedinUrl.isNotEmpty),
                if (instagramUrl.isNotEmpty)
                  _linkRow(Icons.camera_alt_rounded, AppColors.instagram, 'Instagram', instagramUrl, twitterUrl.isNotEmpty || linkedinUrl.isNotEmpty),
                if (twitterUrl.isNotEmpty)
                  _linkRow(Icons.alternate_email_rounded, const Color(0xFF1DA1F2), 'Twitter / X', twitterUrl, linkedinUrl.isNotEmpty),
                if (linkedinUrl.isNotEmpty)
                  _linkRow(Icons.work_rounded, const Color(0xFF0A66C2), 'LinkedIn', linkedinUrl, false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]);
    }

    return widgets;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color color, String label, String value, bool divider) {
    return Column(
      children: [
        if (divider) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tagRow(IconData icon, Color color, String label, String value, bool divider) {
    final tags = value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    return Column(
      children: [
        if (divider) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _linkRow(IconData icon, Color color, String label, String url, bool showDivider) {
    return Column(
      children: [
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
        InkWell(
          onTap: () async {
            String target = url;
            if (!target.startsWith('http://') && !target.startsWith('https://')) {
              target = 'https://$target';
            }
            final uri = Uri.tryParse(target);
            if (uri != null && await canLaunchUrl(uri)) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        url,
                        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, size: 16, color: color.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
