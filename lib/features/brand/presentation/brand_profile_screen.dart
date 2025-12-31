import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/brand_profile_repository.dart';

class BrandProfileScreen extends ConsumerWidget {
  const BrandProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(brandProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(brandProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Profile Header
              _buildProfileHeader(profile),
              const SizedBox(height: 32),
              
              // Profile Information Section
              _buildSectionTitle('Profile Information'),
              const SizedBox(height: 12),
              _buildProfileInfoCard(context, ref, profile),
              const SizedBox(height: 24),
              
              // Settings Section
              _buildSectionTitle('Settings'),
              const SizedBox(height: 12),
              _buildSettingsCard(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BrandProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.business, size: 40, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.companyName ?? 'Brand Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.contactName ?? 'Contact Name',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, WidgetRef ref, BrandProfile profile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.business,
            title: 'Brand Name',
            subtitle: profile.companyName ?? 'Not set',
            onTap: () => _showEditDialog(context, ref, 'Brand Name', profile.companyName, (value) {
              final updated = BrandProfile(
                companyName: value,
                contactName: profile.contactName,
                phone: profile.phone,
                roleInCompany: profile.roleInCompany,
              );
              ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
                ref.invalidate(brandProfileProvider);
              });
            }),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.person,
            title: 'Your Name',
            subtitle: profile.contactName ?? 'Not set',
            onTap: () => _showEditDialog(context, ref, 'Your Name', profile.contactName, (value) {
              final updated = BrandProfile(
                companyName: profile.companyName,
                contactName: value,
                phone: profile.phone,
                roleInCompany: profile.roleInCompany,
              );
              ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
                ref.invalidate(brandProfileProvider);
              });
            }),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.phone,
            title: 'Phone Number',
            subtitle: profile.phone ?? 'Not set',
            onTap: () => _showEditDialog(context, ref, 'Phone Number', profile.phone, (value) {
              final updated = BrandProfile(
                companyName: profile.companyName,
                contactName: profile.contactName,
                phone: value,
                roleInCompany: profile.roleInCompany,
              );
              ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
                ref.invalidate(brandProfileProvider);
              });
            }),
          ),
          const Divider(height: 1),
          _buildInfoTile(
            icon: Icons.work,
            title: 'Your Role',
            subtitle: profile.roleInCompany ?? 'Not set',
            onTap: () => _showRoleDialog(context, ref, profile),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? AppColors.primary).withOpacity(0.1),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String field, String? currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$field updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, BrandProfile profile) {
    final roles = [
      'Head Marketing',
      'Marketing Manager',
      'HR Manager',
      'Brand Manager',
      'CEO',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Your Role'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: roles.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(roles[index]),
                onTap: () {
                  final updated = BrandProfile(
                    companyName: profile.companyName,
                    contactName: profile.contactName,
                    phone: profile.phone,
                    roleInCompany: roles[index],
                  );
                  ref.read(brandProfileRepositoryProvider).updateProfile(updated).then((_) {
                    ref.invalidate(brandProfileProvider);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role updated to ${roles[index]}')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
