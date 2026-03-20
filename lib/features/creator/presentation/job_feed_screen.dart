import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../data/job_repository.dart';
import '../data/user_profile_repository.dart';
import 'widgets/job_card.dart';
import '../../notifications/presentation/notifications_screen.dart';

class JobFeedScreen extends ConsumerStatefulWidget {
  const JobFeedScreen({super.key});

  @override
  ConsumerState<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends ConsumerState<JobFeedScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Instagram', 'YouTube', 'Twitter', 'Tech'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilters(List<dynamic> jobs) {
    return jobs.where((j) {
      final title = (j['title'] ?? '').toString().toLowerCase();
      final brandName = (j['brand_name'] ?? '').toString().toLowerCase();
      final description = (j['description'] ?? '').toString().toLowerCase();
      final platform = (j['platform'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          title.contains(_searchQuery) ||
          brandName.contains(_searchQuery) ||
          description.contains(_searchQuery);

      final matchesPlatform = _selectedFilter == 'All' ||
          platform == _selectedFilter.toLowerCase();

      return matchesSearch && matchesPlatform;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final jobRepo = ref.watch(jobRepositoryProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          profileAsync.when(
                            data: (p) => Text(
                              'Hello, ${p.name?.split(' ').first ?? 'Creator'} 👋',
                              style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                              ),
                            ),
                            loading: () => const SizedBox(height: 22, width: 160, child: _SkeletonBox()),
                            error: (_, __) => const Text(
                              'Find Work 🔍',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Discover your next collab',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const NotificationBell(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Glass search bar with active glow
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.border,
                        width: _searchQuery.isNotEmpty ? 1.5 : 1,
                      ),
                      boxShadow: _searchQuery.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.search_rounded,
                          color: _searchQuery.isNotEmpty ? AppColors.primary : AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search jobs, brands...',
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gradient filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final f = _filters[index];
                        final isSelected = f == _selectedFilter;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.brandGradient : null,
                              color: isSelected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Section title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? 'Search results' : 'Recommended for you',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                        ),
                      ),
                      FutureBuilder<List<dynamic>>(
                        future: jobRepo.getFeed(),
                        builder: (ctx, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final count = _applyFilters(snap.data!).length;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count job${count == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Job list
          FutureBuilder<List<dynamic>>(
            future: jobRepo.getFeed(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _JobCardSkeleton(),
                      ),
                      childCount: 4,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Couldn\'t load jobs',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final jobs = snapshot.data ?? [];
              final filtered = _applyFilters(jobs);

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(
                            gradient: AppColors.navSelectedGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 34, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results found' : 'No jobs found',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different keyword or clear the search'
                              : 'Try a different filter or\ncheck back later',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.close_rounded, size: 14),
                            label: const Text('Clear search'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: JobCard(job: filtered[index]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 160, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 100, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 11, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 6),
          Container(height: 11, width: 200, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }
}
