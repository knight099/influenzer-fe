import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../creator/data/creator_repository.dart';
import 'widgets/creator_card.dart';

class CreatorSearchScreen extends ConsumerStatefulWidget {
  const CreatorSearchScreen({super.key});

  @override
  ConsumerState<CreatorSearchScreen> createState() => _CreatorSearchScreenState();
}

class _CreatorSearchScreenState extends ConsumerState<CreatorSearchScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Instagram', 'YouTube', 'Tech', 'Comedy', 'Fashion'];
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

  List<dynamic> _applyFilters(List<dynamic> creators) {
    return creators.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final niche = (c['niche'] ?? '').toString().toLowerCase();
      final city = (c['city'] ?? '').toString().toLowerCase();

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          niche.contains(_searchQuery) ||
          city.contains(_searchQuery);

      bool matchesPlatform = true;
      if (_selectedFilter == 'Instagram') {
        matchesPlatform = c['instagram_username'] != null;
      } else if (_selectedFilter == 'YouTube') {
        matchesPlatform = c['youtube_channel_id'] != null;
      } else if (_selectedFilter != 'All') {
        matchesPlatform = niche.contains(_selectedFilter.toLowerCase());
      }

      return matchesSearch && matchesPlatform;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final creatorsAsync = ref.watch(cachedCreatorSearchProvider);

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Creators',
                        style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Find the perfect match for your brand',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty ? AppColors.primary : AppColors.border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8, offset: const Offset(0, 2),
                        ),
                      ],
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
                            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Search creators, niches, cities...',
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

                  // Filter chips
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
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
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

                  const SizedBox(height: 24),

                  // Spotlight section
                  _SpotlightSection(),

                  const SizedBox(height: 20),

                  // Section title + count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? 'Search results' : 'All Creators',
                        style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                        ),
                      ),
                      creatorsAsync.when(
                        data: (list) {
                          final count = _applyFilters(list).length;
                          return Text(
                            '$count creator${count == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // Creator list
          creatorsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _CreatorCardSkeleton(),
                  ),
                  childCount: 4,
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Couldn\'t load creators',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(cachedCreatorSearchProvider),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (creators) {
              final filtered = _applyFilters(creators);

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.subtleGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_search_rounded, size: 34, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No results found' : 'No creators found',
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CreatorCard(creator: filtered[index]),
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

// ── Spotlight Section ─────────────────────────────────────────────────────────

class _SpotlightSection extends ConsumerWidget {
  const _SpotlightSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(spotlightCreatorsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (creators) {
        if (creators.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'SPOTLIGHT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Featured Creators',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: creators.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _SpotlightCard(
                    creator: creators[index] as Map<String, dynamic>,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Map<String, dynamic> creator;
  const _SpotlightCard({required this.creator});

  @override
  Widget build(BuildContext context) {
    final name = creator['name'] ?? 'Creator';
    final niche = creator['niche']?.toString().trim();
    final city = creator['city']?.toString() ?? '';

    final igFollowers = creator['instagram_followers'];
    final ytSubscribers =
        int.tryParse(creator['youtube_subscribers']?.toString() ?? '0') ?? 0;
    final igCount = igFollowers is int
        ? igFollowers
        : int.tryParse(igFollowers?.toString() ?? '0') ?? 0;

    final isYouTube = ytSubscribers > igCount;
    final followers = isYouTube ? ytSubscribers : igCount;
    final platformColor =
        isYouTube ? AppColors.youtube : AppColors.instagram;
    final platformIcon = isYouTube
        ? Icons.play_circle_fill_rounded
        : Icons.camera_alt_rounded;

    String? avatarUrl = creator['avatar_url']?.toString();
    final cs = creator['cached_stats'];
    if (cs != null) {
      avatarUrl = cs['instagram']?['profile_picture'] ??
          cs['youtube']?['thumbnail'] ??
          avatarUrl;
    }

    return GestureDetector(
      onTap: () => context.push('/creator-details', extra: creator),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: platformColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: platformColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top gradient header with avatar
            Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    platformColor.withOpacity(0.15),
                    platformColor.withOpacity(0.05),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: platformColor.withOpacity(0.5), width: 2,
                        ),
                        color: AppColors.border,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: platformColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface, width: 1.5,
                          ),
                        ),
                        child: Icon(platformIcon,
                            size: 9, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (niche != null && niche.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        city.isNotEmpty ? '$niche · $city' : niche,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (followers > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: platformColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(platformIcon,
                                size: 10, color: platformColor),
                            const SizedBox(width: 3),
                            Text(
                              _fmt(followers),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: platformColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _CreatorCardSkeleton extends StatelessWidget {
  const _CreatorCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 58, height: 58,
            decoration: const BoxDecoration(color: AppColors.border, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 11, width: 100, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 10),
                Container(height: 24, width: 80, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
