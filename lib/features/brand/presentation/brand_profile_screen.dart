import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/brand_profile_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';

class BrandProfileScreen extends ConsumerWidget {
  const BrandProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(brandProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(brandProfileProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _BrandHero(profile: profile)),

            // Wallet / subscription banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _WalletBanner(profile: profile),
              ),
            ),

            // Profile info section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Company Info'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _ProfileInfoCard(profile: profile, ref: ref),
              ),
            ),

            // About the Brand
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'About the Brand'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _AboutCard(profile: profile, ref: ref),
              ),
            ),

            // Brand Details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Brand Details'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _BrandDetailsCard(profile: profile, ref: ref),
              ),
            ),

            // Social Links
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Social Links'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _SocialLinksCard(profile: profile, ref: ref),
              ),
            ),

            // Campaign Focus
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Campaign Focus'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _CampaignFocusCard(profile: profile, ref: ref),
              ),
            ),

            // Settings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _SectionLabel(label: 'Settings'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                child: _SettingsCard(ref: ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _BrandHero extends StatelessWidget {
  final BrandProfile profile;
  const _BrandHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final companyName = profile.companyName ?? 'Brand';
    final initial = companyName.isNotEmpty ? companyName[0].toUpperCase() : 'B';
    final isActive = profile.subscriptionStatus == 'ACTIVE';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover gradient
        Container(
          height: 160,
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          child: Stack(
            children: [
              Positioned(
                top: -20, right: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -10, left: 20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + badge row
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 4),
                      gradient: AppColors.brandGradient,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16, offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: profile.logoUrl != null
                          ? Image.network(
                              profile.logoUrl!,
                              width: 88, height: 88,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.successLight : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.success.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.verified_rounded : Icons.bolt_rounded,
                          size: 13,
                          color: isActive ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive ? 'Pro Brand' : 'Free Plan',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                companyName,
                style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (profile.contactName != null)
                Text(
                  profile.contactName!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BRAND',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Wallet banner ─────────────────────────────────────────────────────────────

class _WalletBanner extends StatelessWidget {
  final BrandProfile profile;
  const _WalletBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final isActive = profile.subscriptionStatus == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wallet
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${profile.walletBalance}',
                  style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1, height: 40,
            color: Colors.white.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          // Subscription
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isActive ? 'Pro Active' : 'Free Plan',
                style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isActive ? 'All features unlocked' : 'Upgrade for more',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Profile info card ─────────────────────────────────────────────────────────

class _ProfileInfoCard extends StatelessWidget {
  final BrandProfile profile;
  final WidgetRef ref;
  const _ProfileInfoCard({required this.profile, required this.ref});

  void _update(BuildContext context, String field, String? currentValue, BrandProfile Function(String) builder) {
    final controller = TextEditingController(text: currentValue ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        field: field,
        controller: controller,
        onSave: (value) {
          ref.read(brandProfileRepositoryProvider).updateProfile(builder(value)).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }

  void _showRolePicker(BuildContext context) {
    const roles = ['Head Marketing', 'Marketing Manager', 'HR Manager', 'Brand Manager', 'CEO', 'Other'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleSheet(
        roles: roles,
        current: profile.roleInCompany,
        onSelect: (role) {
          final updated = BrandProfile(
            companyName: profile.companyName,
            contactName: profile.contactName,
            phone: profile.phone,
            roleInCompany: role,
            website: profile.website,
          );
          ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.storefront_rounded,
            iconColor: AppColors.primary,
            label: 'Brand Name',
            value: profile.companyName ?? 'Not set',
            showDivider: true,
            onTap: () => _update(context, 'Brand Name', profile.companyName,
                (v) => BrandProfile(companyName: v, contactName: profile.contactName, phone: profile.phone, roleInCompany: profile.roleInCompany, website: profile.website)),
          ),
          _InfoRow(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Contact Name',
            value: profile.contactName ?? 'Not set',
            showDivider: true,
            onTap: () => _update(context, 'Contact Name', profile.contactName,
                (v) => BrandProfile(companyName: profile.companyName, contactName: v, phone: profile.phone, roleInCompany: profile.roleInCompany, website: profile.website)),
          ),
          _InfoRow(
            icon: Icons.phone_rounded,
            iconColor: AppColors.success,
            label: 'Phone',
            value: profile.phone ?? 'Not set',
            showDivider: true,
            onTap: () => _update(context, 'Phone', profile.phone,
                (v) => BrandProfile(companyName: profile.companyName, contactName: profile.contactName, phone: v, roleInCompany: profile.roleInCompany, website: profile.website)),
          ),
          _InfoRow(
            icon: Icons.badge_rounded,
            iconColor: AppColors.warning,
            label: 'Your Role',
            value: profile.roleInCompany ?? 'Not set',
            showDivider: true,
            onTap: () => _showRolePicker(context),
          ),
          _InfoRow(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF6366F1),
            label: 'Website',
            value: profile.website?.isNotEmpty == true ? profile.website! : 'Not set',
            showDivider: false,
            onTap: () => _update(context, 'Website', profile.website,
                (v) => BrandProfile(companyName: profile.companyName, contactName: profile.contactName, phone: profile.phone, roleInCompany: profile.roleInCompany, website: v)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool showDivider;
  final VoidCallback onTap;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}

// ── Bottom sheet editor ───────────────────────────────────────────────────────

class _EditSheet extends StatelessWidget {
  final String field;
  final TextEditingController controller;
  final void Function(String) onSave;

  const _EditSheet({required this.field, required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit $field',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter $field',
              prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    onSave(controller.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$field updated')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleSheet extends StatelessWidget {
  final List<String> roles;
  final String? current;
  final void Function(String) onSelect;

  const _RoleSheet({required this.roles, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Select Your Role',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          ...roles.map((role) {
            final isSelected = role == current;
            return GestureDetector(
              onTap: () {
                onSelect(role);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Role updated to $role')),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary.withOpacity(0.4) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── About Card ────────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  final BrandProfile profile;
  final WidgetRef ref;
  const _AboutCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    final desc = profile.description?.isNotEmpty == true ? profile.description! : null;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    desc ?? 'Add a description of your brand...',
                    style: TextStyle(
                      fontSize: 14,
                      color: desc != null ? AppColors.textPrimary : AppColors.textHint,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showEditSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBrandDetailsSheet(
        profile: profile,
        initialSection: 'about',
        onSave: (updated) {
          ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }
}

// ── Brand Details Card ────────────────────────────────────────────────────────

class _BrandDetailsCard extends StatelessWidget {
  final BrandProfile profile;
  final WidgetRef ref;
  const _BrandDetailsCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.category_rounded,
            iconColor: const Color(0xFF6366F1),
            label: 'Industry',
            value: profile.industry?.isNotEmpty == true ? profile.industry! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.warning,
            label: 'Founded Year',
            value: (profile.foundedYear != null && profile.foundedYear! > 0) ? profile.foundedYear.toString() : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.people_rounded,
            iconColor: AppColors.success,
            label: 'Company Size',
            value: profile.companySize?.isNotEmpty == true ? profile.companySize! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.error,
            label: 'Headquarters',
            value: profile.headquarters?.isNotEmpty == true ? profile.headquarters! : 'Not set',
            showDivider: false,
            onTap: () => _showEditSheet(context),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBrandDetailsSheet(
        profile: profile,
        initialSection: 'details',
        onSave: (updated) {
          ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }
}

// ── Social Links Card ─────────────────────────────────────────────────────────

class _SocialLinksCard extends StatelessWidget {
  final BrandProfile profile;
  final WidgetRef ref;
  const _SocialLinksCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.camera_alt_rounded,
            iconColor: AppColors.instagram,
            label: 'Instagram',
            value: profile.instagramUrl?.isNotEmpty == true ? profile.instagramUrl! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.alternate_email_rounded,
            iconColor: const Color(0xFF1DA1F2),
            label: 'Twitter / X',
            value: profile.twitterUrl?.isNotEmpty == true ? profile.twitterUrl! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.work_rounded,
            iconColor: const Color(0xFF0A66C2),
            label: 'LinkedIn',
            value: profile.linkedinUrl?.isNotEmpty == true ? profile.linkedinUrl! : 'Not set',
            showDivider: false,
            onTap: () => _showEditSheet(context),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBrandDetailsSheet(
        profile: profile,
        initialSection: 'social',
        onSave: (updated) {
          ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }
}

// ── Campaign Focus Card ───────────────────────────────────────────────────────

class _CampaignFocusCard extends StatelessWidget {
  final BrandProfile profile;
  final WidgetRef ref;
  const _CampaignFocusCard({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.shopping_bag_rounded,
            iconColor: AppColors.primary,
            label: 'Product Categories',
            value: profile.productCategories?.isNotEmpty == true ? profile.productCategories! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.groups_rounded,
            iconColor: const Color(0xFF0EA5E9),
            label: 'Target Audience',
            value: profile.targetAudience?.isNotEmpty == true ? profile.targetAudience! : 'Not set',
            showDivider: true,
            onTap: () => _showEditSheet(context),
          ),
          _InfoRow(
            icon: Icons.campaign_rounded,
            iconColor: AppColors.warning,
            label: 'Campaign Types',
            value: profile.campaignTypes?.isNotEmpty == true ? profile.campaignTypes! : 'Not set',
            showDivider: false,
            onTap: () => _showEditSheet(context),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBrandDetailsSheet(
        profile: profile,
        initialSection: 'campaign',
        onSave: (updated) {
          ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
            ref.invalidate(brandProfileProvider);
          });
        },
      ),
    );
  }
}

// ── Edit Brand Details Sheet ──────────────────────────────────────────────────

class _EditBrandDetailsSheet extends StatefulWidget {
  final BrandProfile profile;
  final String initialSection;
  final void Function(BrandProfile) onSave;

  const _EditBrandDetailsSheet({
    required this.profile,
    required this.initialSection,
    required this.onSave,
  });

  @override
  State<_EditBrandDetailsSheet> createState() => _EditBrandDetailsSheetState();
}

class _EditBrandDetailsSheetState extends State<_EditBrandDetailsSheet> {
  late TextEditingController _descriptionCtrl;
  late TextEditingController _industryCtrl;
  late TextEditingController _foundedYearCtrl;
  late TextEditingController _headquartersCtrl;
  late TextEditingController _instagramCtrl;
  late TextEditingController _twitterCtrl;
  late TextEditingController _linkedinCtrl;
  late TextEditingController _productCategoriesCtrl;
  late TextEditingController _targetAudienceCtrl;
  late TextEditingController _campaignTypesCtrl;
  String? _selectedCompanySize;

  static const _companySizes = ['1-10', '11-50', '51-200', '200+'];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _descriptionCtrl = TextEditingController(text: p.description ?? '');
    _industryCtrl = TextEditingController(text: p.industry ?? '');
    _foundedYearCtrl = TextEditingController(text: (p.foundedYear != null && p.foundedYear! > 0) ? p.foundedYear.toString() : '');
    _headquartersCtrl = TextEditingController(text: p.headquarters ?? '');
    _instagramCtrl = TextEditingController(text: p.instagramUrl ?? '');
    _twitterCtrl = TextEditingController(text: p.twitterUrl ?? '');
    _linkedinCtrl = TextEditingController(text: p.linkedinUrl ?? '');
    _productCategoriesCtrl = TextEditingController(text: p.productCategories ?? '');
    _targetAudienceCtrl = TextEditingController(text: p.targetAudience ?? '');
    _campaignTypesCtrl = TextEditingController(text: p.campaignTypes ?? '');
    _selectedCompanySize = p.companySize?.isNotEmpty == true ? p.companySize : null;
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _industryCtrl.dispose();
    _foundedYearCtrl.dispose();
    _headquartersCtrl.dispose();
    _instagramCtrl.dispose();
    _twitterCtrl.dispose();
    _linkedinCtrl.dispose();
    _productCategoriesCtrl.dispose();
    _targetAudienceCtrl.dispose();
    _campaignTypesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final p = widget.profile;
    final updated = BrandProfile(
      companyName: p.companyName,
      contactName: p.contactName,
      phone: p.phone,
      roleInCompany: p.roleInCompany,
      website: p.website,
      logoUrl: p.logoUrl,
      walletBalance: p.walletBalance,
      subscriptionStatus: p.subscriptionStatus,
      description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : p.description,
      industry: _industryCtrl.text.trim().isNotEmpty ? _industryCtrl.text.trim() : p.industry,
      foundedYear: int.tryParse(_foundedYearCtrl.text.trim()) ?? p.foundedYear,
      companySize: _selectedCompanySize ?? p.companySize,
      headquarters: _headquartersCtrl.text.trim().isNotEmpty ? _headquartersCtrl.text.trim() : p.headquarters,
      instagramUrl: _instagramCtrl.text.trim().isNotEmpty ? _instagramCtrl.text.trim() : p.instagramUrl,
      twitterUrl: _twitterCtrl.text.trim().isNotEmpty ? _twitterCtrl.text.trim() : p.twitterUrl,
      linkedinUrl: _linkedinCtrl.text.trim().isNotEmpty ? _linkedinCtrl.text.trim() : p.linkedinUrl,
      productCategories: _productCategoriesCtrl.text.trim().isNotEmpty ? _productCategoriesCtrl.text.trim() : p.productCategories,
      targetAudience: _targetAudienceCtrl.text.trim().isNotEmpty ? _targetAudienceCtrl.text.trim() : p.targetAudience,
      campaignTypes: _campaignTypesCtrl.text.trim().isNotEmpty ? _campaignTypesCtrl.text.trim() : p.campaignTypes,
    );
    widget.onSave(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit Brand Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
                children: [
                  const Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _field('Description', _descriptionCtrl, maxLines: 4),

                  const Text('Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _field('Industry', _industryCtrl),
                  _field('Founded Year', _foundedYearCtrl, keyboardType: TextInputType.number),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Company Size', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _companySizes.map((s) {
                            final selected = _selectedCompanySize == s;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCompanySize = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryLight : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? AppColors.primary.withOpacity(0.4) : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  _field('Headquarters', _headquartersCtrl),

                  const Text('Social Links', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _field('Instagram URL', _instagramCtrl, keyboardType: TextInputType.url),
                  _field('Twitter / X URL', _twitterCtrl, keyboardType: TextInputType.url),
                  _field('LinkedIn URL', _linkedinCtrl, keyboardType: TextInputType.url),

                  const Text('Campaign Focus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textHint, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  _field('Product Categories (comma-separated)', _productCategoriesCtrl),
                  _field('Target Audience', _targetAudienceCtrl, maxLines: 2),
                  _field('Campaign Types (comma-separated)', _campaignTypesCtrl),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final WidgetRef ref;
  const _SettingsCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _SettingsRow(
            icon: Icons.notifications_rounded,
            iconColor: AppColors.primary,
            title: 'Notifications',
            subtitle: 'View your alerts',
            showDivider: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          _SettingsRow(
            icon: Icons.privacy_tip_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Privacy',
            subtitle: 'Data & privacy settings',
            showDivider: true,
            onTap: () => _showPrivacy(context),
          ),
          _SettingsRow(
            icon: Icons.help_outline_rounded,
            iconColor: AppColors.textSecondary,
            title: 'Help & Support',
            subtitle: 'FAQs, contact us',
            showDivider: true,
            onTap: () => _showHelpSupport(context),
          ),
          _SettingsRow(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF6366F1),
            title: 'About',
            subtitle: 'Version 1.0.0',
            showDivider: true,
            onTap: () => _showAbout(context),
          ),
          _SettingsRow(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            titleColor: AppColors.error,
            showDivider: false,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final bool showDivider;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: titleColor ?? AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: titleColor ?? AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
      ],
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 160, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              _box(160, 20),
              const SizedBox(height: 8),
              _box(120, 14),
              const SizedBox(height: 24),
              _box(double.infinity, 100, radius: 20),
              const SizedBox(height: 16),
              _box(double.infinity, 200, radius: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _box(double w, double h, {double radius = 8}) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Privacy sheet ─────────────────────────────────────────────────────────────

void _showPrivacy(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                children: [
                  const Text(
                    'Privacy & Data',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'How we handle your information',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _PrivacySection(
                    icon: Icons.lock_rounded,
                    iconColor: AppColors.primary,
                    title: 'Data We Collect',
                    body: 'We collect your name, email, company information, and campaign data to provide our services. Social platform stats are fetched only with your explicit permission.',
                  ),
                  const SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.share_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    title: 'Data Sharing',
                    body: 'Your profile details are shared with creators only when they apply to your campaigns. We never sell your personal data to third parties.',
                  ),
                  const SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.security_rounded,
                    iconColor: AppColors.success,
                    title: 'Data Security',
                    body: 'All data is encrypted in transit (TLS 1.3) and at rest. Tokens and credentials are stored securely using industry-standard encryption.',
                  ),
                  const SizedBox(height: 16),
                  _PrivacySection(
                    icon: Icons.delete_rounded,
                    iconColor: AppColors.error,
                    title: 'Data Deletion',
                    body: 'You can request deletion of your account and all associated data at any time by contacting support@influenzer.in.',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse('https://influenzer.in/privacy');
                        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('View Full Privacy Policy'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri(
                          scheme: 'mailto',
                          path: 'support@influenzer.in',
                          query: 'subject=Data Deletion Request',
                        );
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Request Data Deletion'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _PrivacySection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Help & Support sheet ──────────────────────────────────────────────────────

void _showHelpSupport(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HelpSupportSheet(),
  );
}

class _HelpSupportSheet extends StatefulWidget {
  const _HelpSupportSheet();

  @override
  State<_HelpSupportSheet> createState() => _HelpSupportSheetState();
}

class _HelpSupportSheetState extends State<_HelpSupportSheet> {
  int? _expanded;

  static const _faqs = [
    (
      q: 'How do I post a campaign?',
      a: 'Tap the "Post Campaign" button on the dashboard. You need an active subscription to create campaigns.',
    ),
    (
      q: 'How do I find the right creator for my brand?',
      a: 'Use the Discover tab to search creators by niche, platform, and follower count. You can also browse proposals from creators who applied to your campaigns.',
    ),
    (
      q: 'How do I pay a creator?',
      a: 'Once you approve a proposal, you fund the campaign via Razorpay. The money is held in escrow and released to the creator after the work is verified.',
    ),
    (
      q: 'What is the wallet balance?',
      a: 'Your wallet holds funds that are ready for campaign payments. You can top up your wallet or pay directly during campaign funding.',
    ),
    (
      q: 'How do I cancel or close a campaign?',
      a: 'Go to the campaign details page and select "Close Campaign". Note: Funded milestones cannot be cancelled without creator agreement.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find answers or get in touch',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_faqs.length, (i) {
                    final faq = _faqs[i];
                    final isOpen = _expanded == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.primaryLight : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOpen ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _expanded = isOpen ? null : i),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq.q,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isOpen ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                    size: 20,
                                    color: isOpen ? AppColors.primary : AppColors.textHint,
                                  ),
                                ],
                              ),
                              if (isOpen) ...[
                                const SizedBox(height: 10),
                                Text(
                                  faq.a,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text(
                    'Still need help?',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _ContactTile(
                    icon: Icons.email_rounded,
                    iconColor: AppColors.primary,
                    title: 'Email Support',
                    subtitle: 'support@influenzer.in',
                    onTap: () async {
                      final uri = Uri(scheme: 'mailto', path: 'support@influenzer.in',
                          query: 'subject=Brand Support Request - Influenzer');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.chat_bubble_rounded,
                    iconColor: const Color(0xFF25D366),
                    title: 'WhatsApp',
                    subtitle: 'Chat with us on WhatsApp',
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/919999999999?text=Hi+Influenzer+Brand+Support');
                      if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── About sheet ───────────────────────────────────────────────────────────────

void _showAbout(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          const Text(
            'Influenzer',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Version 1.0.0',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where Brands Meet Creators',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _AboutLink(
                  label: 'Terms of Service',
                  onTap: () async {
                    final uri = Uri.parse('https://influenzer.in/terms');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AboutLink(
                  label: 'Privacy Policy',
                  onTap: () async {
                    final uri = Uri.parse('https://influenzer.in/privacy');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Made with ❤️ in India',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    ),
  );
}

class _AboutLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AboutLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
