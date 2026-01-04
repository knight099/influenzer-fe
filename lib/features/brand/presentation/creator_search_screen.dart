import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../creator/data/creator_repository.dart';
import 'widgets/creator_card.dart';

class CreatorSearchScreen extends ConsumerWidget {
  const CreatorSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search creators (e.g. Comedy, Tech)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            onSubmitted: (value) {
              // TODO: Implement search with query parameter
            },
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(label: 'All', isSelected: true),
              _FilterChip(label: 'Instagram'),
              _FilterChip(label: 'YouTube'),
              _FilterChip(label: 'Tech'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ref.watch(cachedCreatorSearchProvider).when(
            data: (creators) {
              if (creators.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(cachedCreatorSearchProvider);
                    await ref.read(cachedCreatorSearchProvider.future);
                  },
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.person_search, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No creators found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  // Invalidate the cache and trigger a new fetch
                  ref.invalidate(cachedCreatorSearchProvider);
                  // Wait for the new data to load
                  await ref.read(cachedCreatorSearchProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: creators.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return CreatorCard(creator: creators[index]);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(cachedCreatorSearchProvider);
                await ref.read(cachedCreatorSearchProvider.future);
              },
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading creators: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pull down to retry',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {},
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? const BorderSide(color: AppColors.primary)
              : const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
