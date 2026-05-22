import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/num_utils.dart';
import '../../creator/data/creator_repository.dart';
import 'widgets/creator_card.dart';

enum _SortBy { relevance, followers, engagement, priceAsc, priceDesc }

enum _AudienceTier { any, nano, micro, mid, macro, mega }

extension on _AudienceTier {
  String get label => switch (this) {
        _AudienceTier.any => 'Any size',
        _AudienceTier.nano => 'Nano (<10K)',
        _AudienceTier.micro => 'Micro (10–100K)',
        _AudienceTier.mid => 'Mid (100K–500K)',
        _AudienceTier.macro => 'Macro (500K–1M)',
        _AudienceTier.mega => 'Mega (1M+)',
      };

  bool matches(int followers) => switch (this) {
        _AudienceTier.any => true,
        _AudienceTier.nano => followers < 10000,
        _AudienceTier.micro => followers >= 10000 && followers < 100000,
        _AudienceTier.mid => followers >= 100000 && followers < 500000,
        _AudienceTier.macro => followers >= 500000 && followers < 1000000,
        _AudienceTier.mega => followers >= 1000000,
      };
}

extension on _SortBy {
  String get label => switch (this) {
        _SortBy.relevance => 'Relevance',
        _SortBy.followers => 'Most followers',
        _SortBy.engagement => 'Highest engagement',
        _SortBy.priceAsc => 'Price: low → high',
        _SortBy.priceDesc => 'Price: high → low',
      };
}

class CreatorSearchScreen extends ConsumerStatefulWidget {
  const CreatorSearchScreen({super.key});

  @override
  ConsumerState<CreatorSearchScreen> createState() => _CreatorSearchScreenState();
}

class _CreatorSearchScreenState extends ConsumerState<CreatorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Quick platform/niche chips
  String _selectedFilter = 'All';
  static const List<String> _quickFilters = [
    'All', 'Instagram', 'YouTube', 'Multi-platform',
    'Tech', 'Comedy', 'Fashion', 'Travel', 'Beauty', 'Fitness', 'Food', 'Lifestyle',
  ];

  // Advanced filters
  _AudienceTier _audienceTier = _AudienceTier.any;
  _SortBy _sortBy = _SortBy.relevance;
  bool _verifiedOnly = false;
  bool _multiPlatformOnly = false;
  bool _aiSearchActive = false;

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

  int _activeAdvancedFilterCount() {
    var n = 0;
    if (_audienceTier != _AudienceTier.any) n++;
    if (_verifiedOnly) n++;
    if (_multiPlatformOnly) n++;
    if (_sortBy != _SortBy.relevance) n++;
    return n;
  }

  int _followerCount(Map<String, dynamic> c) {
    final ig = toInt(c['instagram_followers']);
    final yt = toInt(c['youtube_subscribers']);
    return ig > yt ? ig : yt;
  }

  List<Map<String, dynamic>> _applyFilters(List<dynamic> raw) {
    final list = raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    final bool useAiSearch = _aiSearchActive && _searchQuery.isNotEmpty;
    final filtered = list.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      final niche = c['niche']?.toString().toLowerCase() ?? '';
      final city = c['city']?.toString().toLowerCase() ?? '';

      final matchesSearch = useAiSearch ||
          _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          niche.contains(_searchQuery) ||
          city.contains(_searchQuery);

      final hasIg = c['instagram_username'] != null;
      final hasYt = c['youtube_channel_id'] != null;

      bool matchesQuick = true;
      switch (_selectedFilter) {
        case 'All':
          break;
        case 'Instagram':
          matchesQuick = hasIg;
          break;
        case 'YouTube':
          matchesQuick = hasYt;
          break;
        case 'Multi-platform':
          matchesQuick = hasIg && hasYt;
          break;
        default:
          matchesQuick = niche.contains(_selectedFilter.toLowerCase());
      }

      if (_verifiedOnly && c['verified'] != true) return false;
      if (_multiPlatformOnly && !(hasIg && hasYt)) return false;
      if (!_audienceTier.matches(_followerCount(c))) return false;

      return matchesSearch && matchesQuick;
    }).toList();

    switch (_sortBy) {
      case _SortBy.relevance:
        break;
      case _SortBy.followers:
        filtered.sort((a, b) => _followerCount(b).compareTo(_followerCount(a)));
        break;
      case _SortBy.engagement:
        filtered.sort((a, b) =>
            toDouble(b['engagement_rate']).compareTo(toDouble(a['engagement_rate'])));
        break;
      case _SortBy.priceAsc:
        filtered.sort((a, b) {
          final ap = toInt(a['min_budget']);
          final bp = toInt(b['min_budget']);
          // Push unpriced creators to the end so brand sees real prices first.
          if (ap == 0 && bp == 0) return 0;
          if (ap == 0) return 1;
          if (bp == 0) return -1;
          return ap.compareTo(bp);
        });
        break;
      case _SortBy.priceDesc:
        filtered.sort((a, b) =>
            toInt(b['min_budget']).compareTo(toInt(a['min_budget'])));
        break;
    }

    return filtered;
  }

  Future<void> _openAdvancedFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void apply(VoidCallback fn) {
              fn();
              setSheet(() {});
              setState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filters & sort',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      TextButton(
                        onPressed: () => apply(() {
                          _audienceTier = _AudienceTier.any;
                          _sortBy = _SortBy.relevance;
                          _verifiedOnly = false;
                          _multiPlatformOnly = false;
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SectionLabel('Audience size'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _AudienceTier.values.map((t) {
                      final selected = _audienceTier == t;
                      return _ChoiceChip(
                        label: t.label,
                        selected: selected,
                        onTap: () => apply(() => _audienceTier = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel('Sort by'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _SortBy.values.map((s) {
                      final selected = _sortBy == s;
                      return _ChoiceChip(
                        label: s.label,
                        selected: selected,
                        onTap: () => apply(() => _sortBy = s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel('Quality'),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Verified creators only',
                        style: TextStyle(fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    value: _verifiedOnly,
                    onChanged: (v) => apply(() => _verifiedOnly = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Multi-platform creators only',
                        style: TextStyle(fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('Has both Instagram and YouTube',
                        style: TextStyle(fontSize: 12,
                            color: AppColors.textHint)),
                    value: _multiPlatformOnly,
                    onChanged: (v) => apply(() => _multiPlatformOnly = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useAiSearch = _aiSearchActive && _searchQuery.isNotEmpty;
    final creatorsAsync = useAiSearch
        ? ref.watch(aiSearchCreatorsProvider(
            query: _searchQuery,
            platform: _selectedFilter == 'All' ? null : _selectedFilter,
          ))
        : ref.watch(cachedCreatorSearchProvider);
    final activeAdv = _activeAdvancedFilterCount();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover Creators',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Find the perfect match for your brand',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),

                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _searchQuery.isNotEmpty
                            ? AppColors.primary : AppColors.border,
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
                        Icon(Icons.search_rounded,
                            color: _searchQuery.isNotEmpty
                                ? AppColors.primary : AppColors.textHint,
                            size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search creators, niches, cities...',
                              hintStyle: TextStyle(
                                  color: AppColors.textHint, fontSize: 14),
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: AppColors.textHint),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // AI Semantic Match toggle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _aiSearchActive
                          ? LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.12),
                                AppColors.secondary.withOpacity(0.06),
                              ],
                            )
                          : null,
                      color: _aiSearchActive ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _aiSearchActive
                            ? AppColors.primary.withOpacity(0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: _aiSearchActive ? AppColors.primary : AppColors.textHint,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Semantic Match',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _aiSearchActive ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _aiSearchActive
                                    ? 'Describe your campaign/target audience to match'
                                    : 'Find creators using natural language and custom criteria',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch.adaptive(
                          value: _aiSearchActive,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _aiSearchActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick filter chips + advanced filter button
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _quickFilters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final f = _quickFilters[index];
                              final isSelected = f == _selectedFilter;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedFilter = f),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        activeCount: activeAdv,
                        onTap: _openAdvancedFilters,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _SpotlightSection(),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? 'Search results' : 'All Creators',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      creatorsAsync.when(
                        data: (list) {
                          final count = _applyFilters(list).length;
                          return Text(
                            '$count creator${count == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
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
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded,
                          color: AppColors.error, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text("Couldn't load creators",
                        style: TextStyle(fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('$err',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(cachedCreatorSearchProvider),
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
                          child: Icon(Icons.person_search_rounded,
                              size: 34, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || activeAdv > 0
                              ? 'No results found' : 'No creators found',
                          style: TextStyle(fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different keyword or clear the search'
                              : activeAdv > 0
                                  ? 'Try loosening your filters'
                                  : 'Try a different filter or\ncheck back later',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13,
                              color: AppColors.textSecondary, height: 1.5),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _searchController.clear(),
                            icon: const Icon(Icons.close_rounded, size: 14),
                            label: const Text('Clear search'),
                          ),
                        ] else if (activeAdv > 0) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _audienceTier = _AudienceTier.any;
                              _sortBy = _SortBy.relevance;
                              _verifiedOnly = false;
                              _multiPlatformOnly = false;
                            }),
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Reset filters'),
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

// ── Filter button with active count badge ────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;
  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: hasActive ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded,
                size: 16,
                color: hasActive ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text('Filters',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: hasActive ? Colors.white : AppColors.textSecondary)),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$activeCount',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: AppColors.textHint, letterSpacing: 0.5));
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
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
                      Text('SPOTLIGHT',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('Featured Creators',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
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
                  final raw = creators[index];
                  if (raw is! Map) return const SizedBox.shrink();
                  return _SpotlightCard(
                    creator: raw.cast<String, dynamic>(),
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
    final name = (creator['name']?.toString().isNotEmpty == true)
        ? creator['name'].toString() : 'Creator';
    final niche = creator['niche']?.toString().trim();
    final city = creator['city']?.toString() ?? '';

    final igCount = toInt(creator['instagram_followers']);
    final ytSubscribers = toInt(creator['youtube_subscribers']);

    final isYouTube = ytSubscribers > igCount;
    final followers = isYouTube ? ytSubscribers : igCount;
    final platformColor = isYouTube ? AppColors.youtube : AppColors.instagram;
    final platformIcon = isYouTube
        ? Icons.play_circle_fill_rounded : Icons.camera_alt_rounded;

    String? avatarUrl = isNonEmptyString(creator['avatar_url'])
        ? creator['avatar_url'] as String : null;
    final cs = creator['cached_stats'];
    if (cs is Map) {
      final ig = cs['instagram'];
      final yt = cs['youtube'];
      final candidate = (ig is Map ? ig['profile_picture'] : null) ??
          (yt is Map ? yt['thumbnail'] : null);
      if (isNonEmptyString(candidate)) avatarUrl = candidate as String;
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
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: platformColor.withOpacity(0.5), width: 2,
                        ),
                        color: AppColors.border,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(name),
                              )
                            : _avatarFallback(name),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: platformColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surface, width: 1.5),
                        ),
                        child: Icon(platformIcon, size: 9, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    if (niche != null && niche.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(city.isNotEmpty ? '$niche · $city' : niche,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ],
                    const Spacer(),
                    if (followers > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: platformColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(platformIcon, size: 10, color: platformColor),
                            const SizedBox(width: 3),
                            Text(_fmt(followers),
                                style: TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: platformColor)),
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

  Widget _avatarFallback(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary, fontSize: 20),
        ),
      );

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
            decoration: BoxDecoration(
                color: AppColors.border, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 140,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 11, width: 100,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 10),
                Container(height: 24, width: 80,
                    decoration: BoxDecoration(color: AppColors.border,
                        borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
