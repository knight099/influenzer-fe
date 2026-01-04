import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/brand_profile_repository.dart';
import '../data/campaign_repository.dart';
import 'creator_search_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import 'brand_profile_screen.dart';

class BrandDashboardScreen extends StatefulWidget {
  const BrandDashboardScreen({super.key});

  @override
  State<BrandDashboardScreen> createState() => _BrandDashboardScreenState();
}

class _BrandDashboardScreenState extends State<BrandDashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _widgetOptions => <Widget>[
    const _BrandHomeTab(),
    const CreatorSearchScreen(),
    const ChatListScreen(),
    const BrandProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 // Only show on Home tab
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-campaign'),
              label: const Text('Post Campaign'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _BrandHomeTab extends ConsumerWidget {
  const _BrandHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(brandProfileProvider);
    final campaignRepo = ref.watch(campaignRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Name Header
          profileAsync.when(
            data: (profile) => Text(
              'Welcome back, ${profile.companyName ?? 'Brand'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Active Campaigns Section
          _SectionHeader(
            title: 'Active Campaigns',
            onViewAll: () {
              // Navigate to campaigns tab
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: campaignRepo.listCampaigns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error loading campaigns: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              
              final campaigns = snapshot.data ?? [];
              
              if (campaigns.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.campaign_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No active campaigns yet'),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/create-campaign'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Campaign'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: campaigns.take(3).map((campaign) {
                  return Card(
                    child: ListTile(
                      title: Text(campaign['title'] ?? 'Untitled Campaign'),
                      subtitle: Text('Budget: ₹${campaign['budget'] ?? 0}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/campaign-details', extra: campaign);
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Recent Proposals Section (placeholder for now)
          _SectionHeader(title: 'Recent Proposals', onViewAll: () {}),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent proposals'),
            ),
          ),
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }
}
