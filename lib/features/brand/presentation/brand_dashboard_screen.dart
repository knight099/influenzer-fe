import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
    const Center(child: Text('My Campaigns')), // Placeholder
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
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Jobs',
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
      floatingActionButton: _selectedIndex == 2 // Only show on Jobs tab (or Home?)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-campaign'),
              label: const Text('Post Job'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _BrandHomeTab extends StatelessWidget {
  const _BrandHomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, Nike!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Active Campaigns', onViewAll: () {}),
          const SizedBox(height: 16),
          // Placeholder for Campaign Cards
          const Card(child: ListTile(title: Text('Summer Shoe Launch'), subtitle: Text('3 Proposals'))),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Recent Proposals', onViewAll: () {}),
          const SizedBox(height: 16),
          // Placeholder for Proposals
          const Card(child: ListTile(title: Text('Video by @creator1'), subtitle: Text('Pending Review'))),
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
