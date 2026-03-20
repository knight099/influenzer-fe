import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/brand_profile_repository.dart';
import '../data/campaign_repository.dart';
import 'creator_search_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import 'brand_profile_screen.dart';
import '../../wallet/presentation/subscription_prompt.dart';
import '../../notifications/presentation/notifications_screen.dart';

class BrandDashboardScreen extends ConsumerStatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  ConsumerState<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends ConsumerState<BrandDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    const _BrandHomeTab(),
    const CreatorSearchScreen(),
    const ChatListScreen(),
    const BrandProfileScreen(),
  ];

  void _onTap(int index) => setState(() => _selectedIndex = index);

  void _onPostCampaign() {
    final profileAsync = ref.read(brandProfileProvider);
    final isSubscribed = profileAsync.value?.subscriptionStatus == 'ACTIVE';
    if (isSubscribed) {
      context.push('/create-campaign');
    } else {
      showDialog(
        context: context,
        builder: (_) => SubscriptionPrompt(
          role: 'Brand',
          onSuccess: () => ref.invalidate(brandProfileProvider),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: _onPostCampaign,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text(
                  'Post Campaign',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            )
          : null,
      bottomNavigationBar: _GlassBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
        items: const [
          _NavItemData(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
          _NavItemData(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Discover'),
          _NavItemData(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages'),
          _NavItemData(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class _BrandHomeTab extends ConsumerWidget {
  const _BrandHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(brandProfileProvider);
    final campaignRepo = ref.watch(campaignRepositoryProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (p) => Text(
                              'Hi, ${p.companyName ?? 'Brand'} 👋',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 22, width: 140,
                              child: _SkeletonBox(radius: 6),
                            ),
                            error: (_, __) => const Text(
                              'Welcome back 👋',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your campaigns',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const NotificationBell(),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats banner
                  profileAsync.when(
                    data: (p) => _StatsBanner(walletBalance: p.walletBalance, subscriptionStatus: p.subscriptionStatus),
                    loading: () => const _SkeletonBox(height: 90, radius: 20),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Campaigns section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SectionHeader(
                title: 'Active Campaigns',
                onViewAll: () {},
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: FutureBuilder<List<dynamic>>(
              future: campaignRepo.listMyCampaigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _SkeletonBox(height: 80, radius: 16),
                        SizedBox(height: 12),
                        _SkeletonBox(height: 80, radius: 16),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _ErrorCard(message: 'Failed to load campaigns'),
                  );
                }

                final campaigns = snapshot.data ?? [];
                if (campaigns.isEmpty) {
                  return SliverToBoxAdapter(child: _EmptyCampaigns(ref: ref));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == campaigns.length) return const SizedBox(height: 100);
                      final c = campaigns[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CampaignCard(campaign: c),
                      );
                    },
                    childCount: campaigns.length + 1,
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

class _StatsBanner extends StatelessWidget {
  final dynamic walletBalance;
  final String? subscriptionStatus;

  const _StatsBanner({this.walletBalance, this.subscriptionStatus});

  @override
  Widget build(BuildContext context) {
    final isActive = subscriptionStatus == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${walletBalance ?? 0}',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.lock_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Pro Active' : 'Free Plan',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600,
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

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/campaign-details', extra: campaign),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: AppColors.navSelectedGradient,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign['title'] ?? 'Untitled Campaign',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Budget: ₹${campaign['budget'] ?? 0}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            _CampaignStatusChip(status: (campaign['status'] ?? 'OPEN').toString()),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _EmptyCampaigns extends StatelessWidget {
  final WidgetRef ref;
  const _EmptyCampaigns({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              gradient: AppColors.navSelectedGradient,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.campaign_outlined, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No campaigns yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first campaign\nto start reaching creators',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              final profileAsync = ref.read(brandProfileProvider);
              final isSubscribed = profileAsync.value?.subscriptionStatus == 'ACTIVE';
              if (isSubscribed) {
                context.push('/create-campaign');
              } else {
                showDialog(
                  context: context,
                  builder: (_) => SubscriptionPrompt(
                    role: 'Brand',
                    onSuccess: () => ref.invalidate(brandProfileProvider),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Campaign'),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? height;
  final double radius;

  const _SkeletonBox({this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 16,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _CampaignStatusChip extends StatelessWidget {
  final String status;
  const _CampaignStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'OPEN':
        color = AppColors.success;
        break;
      case 'CLOSED':
        color = AppColors.error;
        break;
      case 'COMPLETED':
        color = const Color(0xFF60A5FA);
        break;
      default:
        color = AppColors.textHint;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}

// ── Glass bottom nav shared components ──────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

class _GlassBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _GlassBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.75),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.09),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  return _GlassNavItem(
                    data: entry.value,
                    index: entry.key,
                    selected: selectedIndex,
                    onTap: onTap,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  final _NavItemData data;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _GlassNavItem({
    required this.data,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.navSelectedGradient : null,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? data.activeIcon : data.icon,
                key: ValueKey(isSelected),
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
